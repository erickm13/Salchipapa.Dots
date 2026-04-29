class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Zellij/Tmux, Neovim & CLI tools"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.0.4.tar.gz"
  sha256 "05b86a3a1bb6820da943be430a8be98940764119db20d29b5e5729320d3851c3"
  version "v2.0.4"

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
