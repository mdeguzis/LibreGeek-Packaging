# New script template code

Update scripts with this code


## Git
```
	git clone -b "${branch}" "${git_url}" "${git_dir}"
	cd "${git_dir}"
	latest_commit=$(git log -n 1 --pretty=format:"%h")

## Before tarball creation:
-----------------------------------------------------------------------------------------------------------------
cd "${build_dir}"

-----------------------------------------------------------------------------------------------------------------
 # update changelog with dch
if [[ -f "debian/changelog" ]]; then

	dch -p --force-distribution -v "${pkgver}+${pkgsuffix}" --package "${pkgname}" -D "${DIST}" -u "${urgency}" \
	"Update to the latest commit ${latest_commit}"
	nano "debian/changelog"

else

	dch --create -p --force-distribution -v "${pkgver}+${pkgsuffix}" --package "${pkgname}" -D "${DIST}" -u "${urgency}" \
	"Update to the latest commit ${latest_commit}"
	nano "debian/changelog"

fi

## Summary actions
-----------------------------------------------------------------------------------------------------------------
	# output finish
	cat<<-EOF
	
	Time started: ${time_stamp_start}
	echo -e "Time started: ${time_stamp_end}
	echo -e "Total Runtime (minutes): $runtime
	EOF
	
	# inform user of packages
	cat<<-EOF
	
	###############################################################
	If package was built without errors you will see it below.
	If you don't, please check build dependcy errors listed above.
	###############################################################
	
	Showing contents of: ${build_dir}
	
	EOF

	ls "${build_dir}" | grep -E "${pkgver}" 

	echo -e "\n==> Would you like to transfer any packages that were built? [y/n]"
	sleep 0.5s
	# capture command
	read -erp "Choice: " transfer_choice

	if [[ "$transfer_choice" == "y" ]]; then

		# transfer files
		if [[ -d "${build_dir}" ]]; then
			rsync -arv --filter="merge ${HOME}/.config/SteamOS-Tools/repo-filter.txt" ${build_dir}/ ${USER}@${HOST}:${REPO_FOLDER}

			# Keep changelog
			cp "${git_dir}/debian/changelog" "${scriptdir}/debian/"
		fi

	elif [[ "$transfer_choice" == "n" ]]; then
		echo -e "Upload not requested\n"
	fi

}

# start main
main
```
