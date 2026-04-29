class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Zellij/Tmux, Neovim & CLI tools"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.1.0.tar.gz"
  sha256 "0b25b8069b2b605a422ef61a034078d7e5e856fafb5a546487c6b51f20413d05"
  version "v2.1.0"

  def install
    (share/"salchipapa-dots").install Dir["*"]
    bin.install "install.sh" => "salchipapa-dots"
  end

  def caveats
    <<~EOS
      Run the installer with:
        sudo salchipapa-dots
    EOS
  end
end
