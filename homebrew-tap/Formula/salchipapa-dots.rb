class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Zellij/Tmux, Neovim & CLI tools"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.0.1.tar.gz"
  sha256 "138eafd7da73bd31c7a1476943d607bfdcbc6937fde17ebd724e564f1dc1cc5d"
  version "v2.0.1"

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
