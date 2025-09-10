{
  description = "Tmux plugin for displaying git worktree information";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = rec {
          tmux-git-worktree = pkgs.tmuxPlugins.mkTmuxPlugin {
            pluginName = "tmux-git-worktree";
            version = "1.0.0";
            src = ./.;
            rtpFilePath = "worktree.tmux";
            meta = with pkgs.lib; {
              homepage = "https://github.com/pcasaretto/nix-home/tree/main/tmux-git-worktree";
              description = "Tmux plugin for displaying git worktree information in status bar";
              license = licenses.mit;
              platforms = platforms.unix;
              maintainers = [ ];
            };
          };
          default = tmux-git-worktree;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            git
            tmux
            bats
          ];
        };

        # Test runner app
        apps = {
          test = {
            type = "app";
            program = "${self}/run-tests.sh";
          };
        };

        # Add a check for CI/CD
        checks = {
          tests = pkgs.stdenv.mkDerivation {
            name = "tmux-git-worktree-tests";
            src = ./.;
            
            buildInputs = with pkgs; [ bats bash git tmux ];
            
            buildPhase = ''
              # Set up environment
              export PLUGIN_DIR="$PWD"
              
              # Run the test suite
              bats tests/*.bats
            '';
            
            installPhase = ''
              mkdir -p $out
              echo "Tests passed" > $out/result
            '';
          };
        };
      }
    );
}