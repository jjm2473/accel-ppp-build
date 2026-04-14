
docker run --privileged --rm tonistiigi/binfmt --install all || exit 1

mkdir -p branch

function build_os() {
	local os=$1
	local branch=$2
	local hash=$3

	local output_file="accel-ppp-$branch-$hash-$os.tar.gz"
	if [ -f output/$output_file ]; then
		echo "Output file $output_file already exists, skipping build."
		return 0
	fi

	mkdir -p output
	rm -rf output/temp

	docker build --output type=local,dest=./output/temp/amd64 --platform linux/amd64 --build-arg ACCEL_PPP_BRANCH=$branch --build-arg ACCEL_PPP_OS=$os . || return 1
	docker build --output type=local,dest=./output/temp/arm64 --platform linux/arm64 --build-arg ACCEL_PPP_BRANCH=$branch --build-arg ACCEL_PPP_OS=$os . || return 1

	tar -C output/temp -czf "$PWD/output/$output_file" amd64 arm64
	rm -rf output/temp

}

function build_branch() {
	local branch=$1

	[ -d branch/$branch ] || git clone --depth=1 -b "$branch" https://github.com/accel-ppp/accel-ppp.git branch/$branch
	git -C branch/$branch pull || return 1

	local HASH=$(git -C branch/$branch rev-parse --short HEAD)
	build_os Debian12 $branch $HASH || return 1
	build_os Debian10 $branch $HASH || return 1
	return 0
}

build_branch master || exit 1
build_branch 1.14.0 || exit 1
# build_branch 1.13.0 || exit 1
