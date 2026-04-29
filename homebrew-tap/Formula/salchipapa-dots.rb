class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Zellij/Tmux, Neovim & CLI tools"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.1.9.tar.gz"
  sha256 "6009710199c02a4a05dfcb149483bf67b7a374801746b264dc3724d64c759ea3"
  version "v2.1.9"

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
