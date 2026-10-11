class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Herdr/Zellij/Tmux, Kitty/WezTerm, Neovim, AI agents & CLI tools (Debian, Arch, WSL)"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.6.0.tar.gz"
  sha256 "8972635a1e19ff7555facf7c80a31ed4a8caa975e24df264318c6bd2f0718fd5"
  version "v2.6.0"

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
