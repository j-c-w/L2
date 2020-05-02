#!/bin/zsh

set -eu
typeset -a build
zparseopts -D -E -build=build

if [[ $# -lt 2 ]]; then
	echo "Usage: $0 <output directory> <tests to run....>"
	echo " --build to rebuild the l2 executable."
	exit 1
fi

# Get python 3.4.3 loaded -- Probably faster this way than through nix
# given that we don't need any special modules.
source /etc/profile.d/modules.sh
module load python/3.4.3 || echo "Python likely already loaded"

output_directory=$1
shift

# Now, go into a nix-shell to execute the rest.
if [[ ${#build} -gt 0 ]]; then
	install_nix.sh $TMPDIR/nix

	enter_nix_shell.sh $TMPDIR/nix "
	nix-env -iA nixpkgs.opam nixpkgs.jbuilder nixpkgs.ocaml nixpkgs.dune nixpkgs.m4 nixpkgs.autoconf
	export OPAMROOT=$TMPDIR/opamroot
	# Setup the cache for opam.
	export XDG_CACHE_HOME=$TMPDIR/cache
	opam init -n
	# Initialize the compiler
	opam switch create compiler ocaml-base-compiler

	# Build the repo
	opam install core core_extended=v0.11.0 hashcons ppx_jane yojson=1.5.0 menhir oUnit --unlock-base
	eval $(opam env)
	jbuilder build @install
	"
fi
cd CodeModels/L2
./classify_all.sh $output_directory $@
