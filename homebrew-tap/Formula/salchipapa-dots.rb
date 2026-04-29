class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Zellij/Tmux, Neovim & CLI tools"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.5.3.tar.gz"
  sha256 "ba120a0d13b49b699be2054a702b714f8c835270bf7ca881f83cf1a587208611"
  version "v2.5.3"

  def install
    bin.install "install.sh" => "salchipapa-dots"
    (share/"salchipapa-dots").install Dir["*"]
  end

  def caveats
    <<~EOS
      Run the installer with:
        sudo salchipapa-dots
    EOS
  end
end
