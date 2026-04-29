class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Zellij/Tmux, Neovim & CLI tools"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "a305186819d3524f90b1b7b9a1433c5135cd2eebf3d27a3d4e69e88309195a5c"
  version "2.0.0"

  def install
    bin.install "install.sh" => "salchipapa-dots"
  end

  def caveats
    <<~EOS
      Run the installer with:
        sudo salchipapa-dots
    EOS
  end
end
