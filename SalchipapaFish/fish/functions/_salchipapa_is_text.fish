# ¿Es un archivo de texto? (para abrirlo en nvim y no con su app). Mira el contenido con `file`, no la
# extensión: Dockerfile, configs sin extensión… cuentan como texto. Los vacíos salen "binary" en
# `file`, pero se abren en nvim. Lo usan Ctrl+T (_salchipapa_fzf_directory) y `ff`.
function _salchipapa_is_text --argument-names path
    not test -s "$path"; and return 0
    test (file --brief --dereference --mime-encoding -- "$path") != binary
end
