class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Herdr/Zellij/Tmux, Kitty/WezTerm, Neovim, AI agents & CLI tools (Debian, Arch, WSL)"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.7.0.tar.gz"
  sha256 "8785cac36324033dee47e441a9444287bf3554a11ce0d009d32d0e5d0b713ffd"
  version "v2.7.0"

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
