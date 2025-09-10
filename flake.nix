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
            
            # Ensure git is available in runtime
            buildInputs = [ pkgs.git ];
            
            # Wrap executable scripts to use Nix bash for the packaged version
            postInstall = ''
              # Only wrap executable files, not sourced files like helpers.sh
              for script in $target/scripts/get_worktree.sh $target/worktree.tmux; do
                if [ -f "$script" ] && [ -x "$script" ]; then
                  wrapProgram "$script" --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.bash pkgs.git pkgs.coreutils ]}"
                fi
              done
            '';
            
            nativeBuildInputs = [ pkgs.makeWrapper ];
            
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
            shellcheck
          ];
        };

        # Test runner app
        apps = {
          test = {
            type = "app";
            program = "${self}/run-tests.sh";
          };
        };

        # Make package available as overlay for integration with tmuxPlugins
        overlays.default = final: prev: {
          tmuxPlugins = prev.tmuxPlugins // {
            git-worktree = self.packages.${final.system}.default;
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