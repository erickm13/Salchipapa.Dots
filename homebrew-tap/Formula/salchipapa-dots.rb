class SalchipapaDots < Formula
  desc "Salchipapa dotfiles installer — Fish/Zsh, Zellij/Tmux, Neovim & CLI tools"
  homepage "https://github.com/erickm13/Salchipapa.Dots"
  url "https://github.com/erickm13/Salchipapa.Dots/archive/refs/tags/v2.0.3.tar.gz"
  sha256 "084f893da9fca85df60a16c00cd2f98f8556ee46b1b20894027ce249fd862122"
  version "v2.0.3"

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
