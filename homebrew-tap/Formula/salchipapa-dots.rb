class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Herdr/Zellij/Tmux, Kitty/WezTerm, Neovim, AI agents & CLI tools (Debian, Arch, WSL)"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.9.0.tar.gz"
  sha256 "182acdaf380b8c9980e94b3058f1f24414ed785db2aa3a5089f52e6d9ea42b51"
  version "v2.9.0"

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
