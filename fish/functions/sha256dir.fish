# function sha256dir --description 'SHA-256 of a folder; -s/--strict adds dirs, links, modes'
#     argparse s/strict -- $argv
#     or return
# 
#     if test (count $argv) -ne 1
#         echo 'usage: sha256dir [-s|--strict] DIR' >&2
#         return 2
#     end
# 
#     set -l dir (path resolve -- $argv[1])
#     test -d $dir; or begin
#         echo "not a directory: $argv[1]" >&2
#         return 1
#     end
# 
#     if set -q _flag_strict
#         begin
#             find $dir -type f -print0 | sort -z | xargs -0 -r sha256sum
#             find $dir \( -type d -o -type l -o -type f \) -printf '%P %y %m %l\n' | sort
#         end | sha256sum
#     else
#         find $dir -type f -print0 | sort -z | xargs -0 -r sha256sum | sha256sum
#     end
# end

function sha256dir --description 'SHA-256 of a folder via fd; -s/--strict adds dirs, links, modes'
    argparse s/strict -- $argv
    or return

    if test (count $argv) -ne 1
        echo 'usage: sha256dir [-s|--strict] DIR' >&2
        return 2
    end

    set -l dir (path resolve -- $argv[1])
    test -d $dir; or begin
        echo "not a directory: $argv[1]" >&2
        return 1
    end

    if set -q _flag_strict
        begin
            fd -uu -tf -0 --base-directory $dir | sort -z | xargs -0 -r sha256sum
            fd -uu -tf -td -tl -0 --base-directory $dir | sort -z | while read -lz p
                set -l mode (stat -c '%a' -- $dir/$p)
                set -l kind (stat -c '%F' -- $dir/$p)
                set -l link ''
                test -L $dir/$p; and set link (readlink -- $dir/$p)
                printf '%s\t%s\t%s\t%s\n' $p $kind $mode $link
            end
        end | sha256sum
    else
        fd -uu -tf -0 --base-directory $dir | sort -z | xargs -0 -r sha256sum | sha256sum
    end
end
