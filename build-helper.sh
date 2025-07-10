#!/bin/bash

[[ -f triples.json ]] || {
	printf '%s\n' "triples.json is missing?"
	exit
}

# Create indexed array and populate it
readarray -t arch_array < <(jq -r '.arch_type[]' triples.json)

if [[ -z $1 && -z $target ]]; then
	printf '\n%s\n\n' "Available architectures:"

	# Display the architectures
	for arch in "${arch_array[@]}"; do
		printf '%s\n' "$arch"
	done

	printf '\n'
	exit 0
fi

# Check if $target is set and matches a value in arch_array
if [[ -n "$target" ]]; then
	target_found=false
	for arch in "${arch_array[@]}"; do
		if [[ "$target" == "$arch" ]]; then
			target_found=true
			break
		fi
	done

	if [[ "$target_found" == false ]]; then
		printf '%s\n' "Error: Environment variable \$target='$target' does not match any available architecture"
		exit 1
	fi
fi

target="${1:-$target}"
target_config=$(jq -r --arg arch "${target}" '.include[] | select(.arch_type == $arch) | .arch_config' triples.json)

if [[ -z "$target_config" ]]; then
	printf '%s\n' "Error: Architecture '$1' not found"
	exit 1
fi

printf '\n%s\n' "target: ${target}"
printf '%s\n\n' "config: ${target_config}"

# sed "s|GCC_CONFIG_FOR_TARGET +=|GCC_CONFIG_FOR_TARGET += ${matrix_arch_config}|" -i config.mak

# sed "s|GCC_CONFIG_FOR_TARGET +=|GCC_CONFIG_FOR_TARGET += ${target_config}|" config.mak

#make -j"$(nproc)" install TARGET="${1}" OUTPUT="/home/gh/build/${matrix_arch_type}"

printf '%s\n\n' "These are the target specific commands you can run manually:"

printf '%s\n\n' "sed -i \"s|^GCC_CONFIG_FOR_TARGET +=.*|GCC_CONFIG_FOR_TARGET += ${target_config}|\" config.mak"
printf '%s\n\n' "docker run -it -w /root -v $(pwd):/root alpine:edge"
printf '%s\n' "apk add -u --no-cache autoconf automake bash bison build-base \ "
printf '%s\n' "curl findutils flex git libarchive-tools libtool linux-headers \ "
printf '%s\n\n' "patch perl pkgconf rsync tar texinfo xz zip "
printf '%s\n\n' "make -j$(nproc) install TARGET=\"${target}\" OUTPUT=\"build/${target}\""
printf '%s\n' "cd \"build\""
printf '%s\n\n' "XZ_OPT=-9T0 tar -cvJf ${target}.tar.xz ${target}/"

printf '%s\n\n' "Or do this command to have them done for you:"
printf '%s\n\n' "./build-helper.sh target build"

if [[ "${2}" == "build" ]]; then
	sed -i "s|^GCC_CONFIG_FOR_TARGET +=.*|GCC_CONFIG_FOR_TARGET += ${target_config}|" config.mak
	docker run -it -w /root -v "$(pwd)":/root alpine:edge /bin/sh -c "docker run -it -v $(pwd):/root alpine:edge
		apk add -u --no-cache autoconf automake bash bison build-base \
		curl findutils flex git libarchive-tools libtool linux-headers \
		patch perl pkgconf rsync tar texinfo xz zip \
		make -j$(nproc) install TARGET=\"${target}\" OUTPUT=\"build/${target}\" \
		cd \"build\ \
		XZ_OPT=-9T0 tar -cvJf ${target}.tar.xz ${target}/"
fi
