#!/bin/sh -e

if [ -z "$1" ] || [ ! -e "$1" ]; then
    echo "Ошибка! Файл не указан или не существует" >&2
    exit 1
fi

file="$1"
dir=$(cd "$(dirname "$file")" && pwd)
filename="${file##*/}"

out=$(grep -m 1 "Output:" "$file" | sed 's/.*Output:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\r')

if [ -z "$out" ]; then
    echo "Ошибка! Не найден Output" >&2
    exit 2
fi

out="${out##*/}"

tmp=$(mktemp -d)

exit_handler() {
    code=$?
    trap - EXIT
    cd / 2>/dev/null || :
    rm -rf "$tmp"
    exit "$code"
}
trap exit_handler EXIT HUP INT QUIT PIPE TERM

cp "$file" "$tmp/"
cd "$tmp"
ext="${filename##*.}"

case "$ext" in
    c)
        gcc "$filename" -o "$out" || { echo "Ошибка компиляции C" >&2; exit 3; }
        ;;
    cpp|cc|cxx)
        g++ "$filename" -o "$out" || { echo "Ошибка компиляции C++" >&2; exit 3; }
        ;;
    tex)
        case "$out" in
            *.pdf) target_pdf="$out" ;;
            *)     target_pdf="${out}.pdf" ;;
        esac

        pdflatex -interaction=nonstopmode -halt-on-error -jobname="${target_pdf%.*}" "$filename" >/dev/null 2>&1 || {
            echo "Ошибка компиляции TeX" >&2
            exit 3
        }
        out="$target_pdf"
        ;;
    *)
        echo "Ошибка! Неизвестный тип файла ($ext)" >&2
        exit 1
        ;;
esac

mv "$out" "$dir/"