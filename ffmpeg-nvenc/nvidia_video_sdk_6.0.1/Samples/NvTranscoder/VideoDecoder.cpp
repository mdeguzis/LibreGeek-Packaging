#include <string.h>
#include <assert.h>
#include <stdio.h>
#include "VideoDecoder.h"

static const char* getProfileName(int profile)
{
    switch (profile) {
        case 66:    return "Baseline";
        case 77:    return "Main";
        case 88:    return "Extended";
        case 100:   return "High";
        case 110:   return "High 10";
        case 122:   return "High 4:2:2";
        case 244:   return "High 4:4:4";
        case 44:    return "CAVLC 4:4:4";
    }

    return "Unknown Profile";
}

static int CUDAAPI HandleVideoData(void* pUserData, CUVIDSOURCEDATAPACKET* pPacket)
{
    assert(pUserData);
    CudaDecoder* pDecoder = (CudaDecoder*)pUserData;

    CUresult oResult = cuvidParseVideoData(pDecoder->m_videoParser, pPacket);
    if(oResult != CUDA_SUCCESS) {
        printf("error!\n");
    }

    return 1;
}

static int CUDAAPI HandleVideoSequence(void* pUserData, CUVIDEOFORMAT* pFormat)
{
    assert(pUserData);
    CudaDecoder* pDecoder = (CudaDecoder*)pUserData;

    if ((pFormat->codec         != pDecoder->m_oVideoDecodeCreateInfo.CodecType) ||         // codec-type
        (pFormat->coded_width   != pDecoder->m_oVideoDecodeCreateInfo.ulWidth)   ||
        (pFormat->coded_height  != pDecoder->m_oVideoDecodeCreateInfo.ulHeight)  ||
        (pFormat->chroma_format != pDecoder->m_oVideoDecodeCreateInfo.ChromaFormat))
    {
        fprintf(stderr, "NvTranscoder doesn't deal with dynamic video format changing\n");
        return 0;
    }

    return 1;
}

static int CUDAAPI HandlePictureDecode(void* pUserData, CUVIDPICPARAMS* pPicParams)
{
    assert(pUserData);
    CudaDecoder* pDecoder = (CudaDecoder*)pUserData;
    pDecoder->m_pFrameQueue->waitUntilFrameAvailable(pPicParams->CurrPicIdx);
    assert(CUDA_SUCCESS == cuvidDecodePicture(pDecoder->m_videoDecoder, pPicParams));
    return 1;
}

static int CUDAAPI HandlePictureDisplay(void* pUserData, CUVIDPARSERDISPINFO* pPicParams)
{
    assert(pUserData);
    CudaDecoder* pDecoder = (CudaDecoder*)pUserData;
    pDecoder->m_pFrameQueue->enqueue(pPicParams);
    pDecoder->m_decodedFrames++;

    return 1;
}

CudaDecoder::CudaDecoder() : m_videoSource(NULL), m_videoParser(NULL), m_videoDecoder(NULL),
    m_ctxLock(NULL), m_decodedFrames(0), m_bFinish(false)
{
}


CudaDecoder::~CudaDecoder(void)
{
    if(m_videoDecoder) cuvidDestroyDecoder(m_videoDecoder);
    if(m_videoParser)  cuvidDestroyVideoParser(m_videoParser);
    if(m_videoSource)  cuvidDestroyVideoSource(m_videoSource);
}

void CudaDecoder::InitVideoDecoder(const char* videoPath, CUvideoctxlock ctxLock, FrameQueue* pFrameQueue,
        int targetWidth, int targetHeight)
{
    assert(videoPath);
    assert(ctxLock);
    assert(pFrameQueue);

    m_pFrameQueue = pFrameQueue;

    CUresult oResult;
    m_ctxLock = ctxLock;

    //init video source
    CUVIDSOURCEPARAMS oVideoSourceParameters;
    memset(&oVideoSourceParameters, 0, sizeof(CUVIDSOURCEPARAMS));
    oVideoSourceParameters.pUserData = this;
    oVideoSourceParameters.pfnVideoDataHandler = HandleVideoData;
    oVideoSourceParameters.pfnAudioDataHandler = NULL;

    oResult = cuvidCreateVideoSource(&m_videoSource, videoPath, &oVideoSourceParameters);
    if (oResult != CUDA_SUCCESS) {
        fprintf(stderr, "cuvidCreateVideoSource failed\n");
        fprintf(stderr, "Please check if the path exists, or the video is a valid H264 file\n");
        exit(-1);
    }

    //init video decoder
    CUVIDEOFORMAT oFormat;
    cuvidGetSourceVideoFormat(m_videoSource, &oFormat, 0);

    if (oFormat.codec != cudaVideoCodec_H264) {
        fprintf(stderr, "The sample only supports H264 input video!\n");
        exit(-1);
    }

    if (oFormat.chroma_format != cudaVideoChromaFormat_420) {
        fprintf(stderr, "The sample only supports 4:2:0 chroma!\n");
        exit(-1);
    }

	CUVIDDECODECREATEINFO oVideoDecodeCreateInfo;
    memset(&oVideoDecodeCreateInfo, 0, sizeof(CUVIDDECODECREATEINFO));
    oVideoDecodeCreateInfo.CodecType = oFormat.codec;
    oVideoDecodeCreateInfo.ulWidth   = oFormat.coded_width;
    oVideoDecodeCreateInfo.ulHeight  = oFormat.coded_height;
    oVideoDecodeCreateInfo.ulNumDecodeSurfaces = FrameQueue::cnMaximumSize;

    // Limit decode memory to 24MB (16M pixels at 4:2:0 = 24M bytes)
    // Keep atleast 6 DecodeSurfaces
    while (oVideoDecodeCreateInfo.ulNumDecodeSurfaces > 6 && 
        oVideoDecodeCreateInfo.ulNumDecodeSurfaces * oFormat.coded_width * oFormat.coded_height > 16 * 1024 * 1024)
    {
        oVideoDecodeCreateInfo.ulNumDecodeSurfaces--;
    }

    oVideoDecodeCreateInfo.ChromaFormat = oFormat.chroma_format;
    oVideoDecodeCreateInfo.OutputFormat = cudaVideoSurfaceFormat_NV12;
    oVideoDecodeCreateInfo.DeinterlaceMode = cudaVideoDeinterlaceMode_Weave;

    if (targetWidth <= 0 || targetHeight <= 0) {
        oVideoDecodeCreateInfo.ulTargetWidth  = oVideoDecodeCreateInfo.ulWidth;
        oVideoDecodeCreateInfo.ulTargetHeight = oVideoDecodeCreateInfo.ulHeight;
    }
    else {
        oVideoDecodeCreateInfo.ulTargetWidth  = targetWidth;
        oVideoDecodeCreateInfo.ulTargetHeight = targetHeight;
    }

    oVideoDecodeCreateInfo.ulNumOutputSurfaces = 2;
    oVideoDecodeCreateInfo.ulCreationFlags = cudaVideoCreate_PreferCUVID;
    oVideoDecodeCreateInfo.vidLock = m_ctxLock;

    oResult = cuvidCreateDecoder(&m_videoDecoder, &oVideoDecodeCreateInfo);
    if (oResult != CUDA_SUCCESS) {
        fprintf(stderr, "cuvidCreateDecoder() failed, error code: %d\n", oResult);
        exit(-1);
    }

    m_oVideoDecodeCreateInfo = oVideoDecodeCreateInfo;

    //init video parser
    CUVIDPARSERPARAMS oVideoParserParameters;
    memset(&oVideoParserParameters, 0, sizeof(CUVIDPARSERPARAMS));
    oVideoParserParameters.CodecType = oVideoDecodeCreateInfo.CodecType;
    oVideoParserParameters.ulMaxNumDecodeSurfaces = oVideoDecodeCreateInfo.ulNumDecodeSurfaces;
    oVideoParserParameters.ulMaxDisplayDelay = 1;
    oVideoParserParameters.pUserData = this;
    oVideoParserParameters.pfnSequenceCallback = HandleVideoSequence;
    oVideoParserParameters.pfnDecodePicture = HandlePictureDecode;
    oVideoParserParameters.pfnDisplayPicture = HandlePictureDisplay;

    oResult = cuvidCreateVideoParser(&m_videoParser, &oVideoParserParameters);
    if (oResult != CUDA_SUCCESS) {
        fprintf(stderr, "cuvidCreateVideoParser failed, error code: %d\n", oResult);
        exit(-1);
    }
}

void CudaDecoder::Start()
{
    CUresult oResult;

    oResult = cuvidSetVideoSourceState(m_videoSource, cudaVideoState_Started);
    assert(oResult == CUDA_SUCCESS);

    while(cuvidGetVideoSourceState(m_videoSource) == cudaVideoState_Started);

    m_bFinish = true;

    m_pFrameQueue->endDecode();
}

void CudaDecoder::GetCodecParam(int* width, int* height, int* frame_rate_num, int* frame_rate_den, int* is_progressive)
{
    assert (width != NULL && height != NULL && frame_rate_num != NULL && frame_rate_den != NULL);
    CUVIDEOFORMAT oFormat;
    cuvidGetSourceVideoFormat(m_videoSource, &oFormat, 0);

    *width  = oFormat.coded_width;
    *height = oFormat.coded_height;
    *frame_rate_num = oFormat.frame_rate.numerator;
    *frame_rate_den = oFormat.frame_rate.denominator;
    *is_progressive = oFormat.progressive_sequence;
}


