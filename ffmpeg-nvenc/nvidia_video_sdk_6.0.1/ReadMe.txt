NVIDIA Video Codec SDK 6.0 Readme and Getting Started Guide

System Requirements

* NVIDIA Kepler/Maxwell based GPU - Refer to the NVIDIA Video developer zone web page (https://developer.nvidia.com/nvidia-video-codec-sdk) for GPUs that support Encoding and Decoding. 
* Windows: Driver version 358.xx or higher
* Linux:   Driver 358.xx or higher
* CUDA 7.5 Toolkit (optional)

[Windows Configuration Requirements]
The following environment variables need to be set to build the sample applications included with the SDK
* For Windows
  - DXSDK_DIR: pointing to the DirectX SDK root directory
    You can download the latest SDK from Microsoft's DirectX website
* For Windows
  - The CUDA 7.5 Toolkit is optional to install (see below on how to get it)
  - CUDA toolkit is used for building CUDA kernels that can interop with NVENC.  

[Linux Configuration Requirements]    
* For Linux
  - X11 and OpenGL, GLUT, GLEW libraries for video playback and display 
  - The CUDA 7.5 Toolkit is optional to install (see below on how to get it)
  - CUDA toolkit is used for building CUDA kernels that can interop with NVENC.  

[Common to all OS platforms]
* NVIDIA Video Codec samples have pre-built CUDA PTX kernels.  To build the Video Codec SDK samples, it is not
  necessary to download the CUDA toolkit to build.
* To download the CUDA 7.5 toolkit, please go to the following web site:
  http://developer.nvidia.com/cuda/cuda-toolkit

Please refer to the samples guide [<SDK Installation Folder>\Samples\NVIDIA_Video_Codec_Samples_Guide.pdf] for details regarding the building and running of the sample applications included with the SDK. 
