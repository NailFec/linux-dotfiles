# Transcode video to DNxHR + PCM in MOV for DaVinci Resolve on Linux.
# Output name: <stem>-DavinciFixed.mov

function _davincifix_usage
    printf '%s\n' \
        'usage: davincifix [-q lb|sq|hq|hqx|444] [-r|--recursive] [-f|--force] [--dry-run] PATH...' \
        '' \
        'Transcode video to DNxHR video and PCM audio in a MOV container for' \
        'DaVinci Resolve on Linux. Each output is named STEM-DavinciFixed.mov' \
        'and written next to its source.' \
        '' \
        '  -q, --quality PROFILE   lb, sq, hq (default), hqx, 444' \
        '                          (also dnxhr_lb, dnxhr_sq, dnxhr_hq, dnxhr_hqx, dnxhr_444)' \
        '  -r, --recursive         descend into directories and convert video files' \
        '  -f, --force             replace an existing STEM-DavinciFixed.mov' \
        '      --dry-run           print the ffmpeg command and do not encode' \
        '  -h, --help              show this help' \
        '' \
        'Profiles:' \
        '  lb   dnxhr_lb   8-bit  4:2:2   proxies' \
        '  sq   dnxhr_sq   8-bit  4:2:2   everyday edit' \
        '  hq   dnxhr_hq   8-bit  4:2:2   default, suited to 1080p' \
        '  hqx  dnxhr_hqx  10-bit 4:2:2   color' \
        '  444  dnxhr_444  10-bit 4:4:4   finishing' \
        '' \
        'Words from the same scale also work: light/proxy, medium, high,' \
        'higher/color/10bit.' \
        '' \
        'Existing outputs are kept unless --force. A failed encode is deleted' \
        'and does not replace a finished file. An interrupted run can leave' \
        'STEM-DavinciFixed.mov.partial; the next run removes it.' \
        '' \
        'Examples:' \
        '  davincifix ./-5.MP4' \
        '  davincifix -q hqx interview.mov' \
        '  davincifix -r -q sq ./footage'
end

# path reads stdin when stdin is a pipe or a file, which steals its arguments.
function _davincifix_path
    path $argv <&-
end

function _davincifix_dest
    set -l infile $argv[1]
    set -l stem (_davincifix_path basename -E -- $infile)
    if test -z "$stem"
        return 2
    end
    if string match -q -- '*-DavinciFixed' -- $stem
        return 64
    end
    set -l dir (_davincifix_path dirname -- $infile)
    if test -z "$dir"
        return 2
    end
    # path normalize exits 1 when the path was already normalized. That is success.
    set -l out (_davincifix_path normalize -- $dir/$stem-DavinciFixed.mov)
    if test -z "$out"
        return 2
    end
    echo $out
    return 0
end

function _davincifix_find
    set -l dir $argv[1]
    set -l exts mp4 m4v mov mkv avi mxf webm mpg mpeg m2v wmv asf flv ts m2ts mts 3gp ogv vob divx y4m
    if command -q fd
        set -l args --type f --ignore-case --no-ignore --no-ignore-parent --absolute-path --print0
        for ext in $exts
            set -a args --extension $ext
        end
        # `.` is the match-all pattern; the directory must not be parsed as the pattern.
        command fd $args -- . $dir
        return
    end

    set -l clauses
    for ext in $exts
        set -a clauses -o -iname "*.$ext"
    end
    set -e clauses[1]
    command find -- $dir -type f \( $clauses \) -print0
end

function _davincifix_remove_partial
    set -l partial $argv[1]
    if not test -e $partial
        return 0
    end
    if not test -f $partial
        echo "davincifix: partial path is not a regular file: $partial" >&2
        return 1
    end
    command rm -f -- $partial
    or begin
        echo "davincifix: could not remove partial: $partial" >&2
        return 1
    end
end

function _davincifix_one
    argparse --name davincifix f/force dry-run 'profile=' 'pix-fmt=' -- $argv
    or return

    if not set -q _flag_profile; or not set -q _flag_pix_fmt; or test (count $argv) -ne 1
        echo 'davincifix: internal error: bad convert arguments' >&2
        return 1
    end

    set -l profile $_flag_profile
    set -l pix_fmt $_flag_pix_fmt
    set -l infile $argv[1]

    if not test -r $infile
        echo "davincifix: cannot read: $infile" >&2
        return 1
    end

    set -l outfile (_davincifix_dest $infile)
    set -l name_rc $status
    if test $name_rc -eq 64
        echo "davincifix: skip, already named for Resolve: $infile" >&2
        return 64
    else if test $name_rc -ne 0; or test -z "$outfile"
        echo "davincifix: cannot build an output name for: $infile" >&2
        return 1
    end

    if test "$infile" = "$outfile"
        echo "davincifix: refusing to overwrite the source: $infile" >&2
        return 1
    end

    set -l outdir (_davincifix_path dirname -- $outfile)
    if not test -w $outdir
        echo "davincifix: directory is not writable: $outdir" >&2
        return 1
    end

    set -l partial $outfile.partial
    if test -e $outfile
        if not test -f $outfile
            echo "davincifix: output path is not a regular file: $outfile" >&2
            return 1
        end
        if not set -q _flag_force
            if not set -q _flag_dry_run
                _davincifix_remove_partial $partial
                or return 1
            end
            echo "davincifix: skip, output exists: $outfile" >&2
            return 64
        end
    end

    # `V` is a real video stream, so an attached cover image is not treated as the picture.
    set -l vcodec (command ffprobe -v error -select_streams V:0 -show_entries stream=codec_name -of csv=p=0 -- $infile </dev/null)
    set -l probe_rc $status
    if test $probe_rc -ne 0
        echo "davincifix: cannot read media: $infile" >&2
        return 1
    end
    if test -z "$vcodec"
        echo "davincifix: no video stream: $infile" >&2
        return 1
    end

    set -l acodec (command ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 -- $infile </dev/null)
    if test -z "$acodec"
        echo "davincifix: no audio stream, writing video only: $infile" >&2
    end

    set -l ffargs -nostdin -hide_banner -y -i $infile -map 0:V:0
    if test -n "$acodec"
        set -a ffargs -map 0:a:0
    end
    set -a ffargs -c:v dnxhd -profile:v $profile -pix_fmt $pix_fmt
    if test -n "$acodec"
        set -a ffargs -c:a pcm_s16le
    end
    # -f mov keeps the container when the temp file does not end in .mov.
    set -a ffargs -movflags +faststart -f mov

    if set -q _flag_dry_run
        echo "davincifix: dry-run $profile $infile -> $outfile" >&2
        string escape -- ffmpeg $ffargs $outfile
        return 0
    end

    _davincifix_remove_partial $partial
    or return 1

    echo "davincifix: $profile $infile -> $outfile" >&2
    command ffmpeg $ffargs $partial
    set -l ff_rc $status
    if test $ff_rc -ne 0
        command rm -f -- $partial
        echo "davincifix: ffmpeg failed ($ff_rc): $infile" >&2
        return 1
    end
    if not test -s $partial
        command rm -f -- $partial
        echo "davincifix: ffmpeg wrote an empty file: $infile" >&2
        return 1
    end

    set -l got (command ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,pix_fmt -of csv=p=0 -- $partial </dev/null)
    if test "$got" != "dnxhd,$pix_fmt"
        command rm -f -- $partial
        echo "davincifix: output check failed ($got): $infile" >&2
        return 1
    end

    # The finished mov is published only after the encode checks out.
    if not set -q _flag_force; and test -e $outfile
        command rm -f -- $partial
        echo "davincifix: skip, output appeared during encode: $outfile" >&2
        return 64
    end

    command mv -f -- $partial $outfile
    or begin
        command rm -f -- $partial
        echo "davincifix: could not move output into place: $outfile" >&2
        return 1
    end
    return 0
end

function davincifix --description 'Transcode video to DaVinci Resolve DNxHR MOV'
    argparse --name davincifix h/help r/recursive f/force dry-run 'q/quality=' -- $argv
    or return

    if set -q _flag_help
        _davincifix_usage
        return 0
    end

    if test (count $argv) -eq 0
        _davincifix_usage >&2
        return 2
    end

    set -l quality hq
    if set -q _flag_quality
        set quality (string lower -- (string trim -- $_flag_quality))
    end

    set -l profile
    set -l pix_fmt
    switch $quality
        case lb light proxy dnxhr_lb
            set profile dnxhr_lb
            set pix_fmt yuv422p
        case sq medium dnxhr_sq
            set profile dnxhr_sq
            set pix_fmt yuv422p
        case hq high dnxhr_hq
            set profile dnxhr_hq
            set pix_fmt yuv422p
        case hqx higher color 10bit 10-bit dnxhr_hqx
            set profile dnxhr_hqx
            set pix_fmt yuv422p10le
        case 444 finish finishing dnxhr_444
            set profile dnxhr_444
            set pix_fmt yuv444p10le
        case '*'
            echo "davincifix: unknown quality '$quality'" >&2
            echo 'davincifix: choose lb, sq, hq (default), hqx, or 444' >&2
            return 2
    end

    if not command -q ffmpeg
        echo 'davincifix: ffmpeg not found' >&2
        return 127
    end
    if not command -q ffprobe
        echo 'davincifix: ffprobe not found' >&2
        return 127
    end

    set -l preflight 0
    set -l files
    set -l dirs
    for raw in $argv
        if not test -e $raw
            echo "davincifix: not found: $raw" >&2
            set preflight 1
            continue
        end
        if test -d $raw
            if not set -q _flag_recursive
                echo "davincifix: directory requires --recursive: $raw" >&2
                set preflight 1
                continue
            end
            set -a dirs (_davincifix_path resolve -- $raw)
            continue
        end
        if not test -f $raw
            echo "davincifix: not a regular file: $raw" >&2
            set preflight 1
            continue
        end
        set -a files (_davincifix_path resolve -- $raw)
    end
    if test $preflight -ne 0
        return 2
    end

    set -l search_failed 0
    for dir in $dirs
        set -l found
        _davincifix_find $dir | while read -lz p
            set -a found (_davincifix_path resolve -- $p)
        end
        set -l find_rc $pipestatus[1]
        if test $find_rc -ne 0
            echo "davincifix: search failed in: $dir" >&2
            set search_failed 1
        end
        if test (count $found) -eq 0
            echo "davincifix: no video files in: $dir" >&2
            set search_failed 1
            continue
        end
        set -a files $found
    end

    if test (count $files) -eq 0
        echo 'davincifix: no video files found' >&2
        return 1
    end

    if test (count $files) -gt 1
        set files (_davincifix_path sort -u -- $files)
    end

    set -l work
    set -l dests
    set -l owners
    set -l collisions 0
    for infile in $files
        set -l dest (_davincifix_dest $infile)
        set -l dest_rc $status
        switch $dest_rc
            case 0
                if contains -- $dest $dests
                    set -l idx (contains -i -- $dest $dests)
                    echo "davincifix: output collision: $dest" >&2
                    echo "davincifix:   $owners[$idx[1]]" >&2
                    echo "davincifix:   $infile" >&2
                    set collisions (math $collisions + 1)
                else
                    set -a dests $dest
                    set -a owners $infile
                    set -a work $infile
                end
            case 64
                set -a work $infile
            case '*'
                echo "davincifix: cannot build an output name for: $infile" >&2
                return 2
        end
    end
    if test $collisions -gt 0
        return 2
    end

    set -l pass
    if set -q _flag_force
        set -a pass --force
    end
    if set -q _flag_dry_run
        set -a pass --dry-run
    end

    set -l n_ok 0
    set -l n_skip 0
    set -l n_fail 0
    for infile in $work
        _davincifix_one $pass --profile $profile --pix-fmt $pix_fmt -- $infile
        switch $status
            case 0
                set n_ok (math $n_ok + 1)
            case 64
                set n_skip (math $n_skip + 1)
            case '*'
                set n_fail (math $n_fail + 1)
        end
    end

    if set -q _flag_dry_run
        echo "davincifix: dry-run $n_ok, skipped $n_skip, failed $n_fail" >&2
    else
        echo "davincifix: converted $n_ok, skipped $n_skip, failed $n_fail" >&2
    end

    if test $n_fail -gt 0; or test $search_failed -ne 0
        return 1
    end
    return 0
end
