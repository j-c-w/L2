{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
	buildInputs = [ opam jbuilder ocaml dune m4 autoconf ];
	SHELL_NAME = "L2";
	shellHook = ''
	eval $(opam env)
		'';
}
