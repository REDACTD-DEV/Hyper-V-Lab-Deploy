function Waiting-Animation {
    $progress = '\', '|', '/', '-'
    $i = 0
    [console]::Write('Doing something...')
    while($true) {
        $char = $progress[$i++ % $progress.Count]
        [console]::Write("$char$([char]0x8)")
        Start-Sleep -Milliseconds 300
    }
}