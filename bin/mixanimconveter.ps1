$cheminFichier = $args[0]
$cheminFichierSortie = $args[1]

$position_regex = "\((.*)\)"

$result = ""
$contenu = Get-Content -Path $cheminFichier
foreach ($ligne in $contenu) {
    switch ($ligne) {
         { $_.StartsWith("tracks/0/keys") } { 
            $m = $ligne -match $position_regex
            $values = $Matches[1] -split ','
            $r = "tracks/0/keys = PackedFloat32Array("
            for ($i = 0; $i -lt $values.Count; $i += 5) {
                $r += $values[$i] # time
                $r += ", "
                $r += [float]$values[$i+1] # ?
                $r += ", "
                $r += [float]$values[$i+2] # x
                $r += ", "
                $r += "0.0" # y
                $r += ", "
                $r += [float]$values[$i+4] + 101.0 # z
                if (($i+5) -lt $values.Count) {
                    $r += ","
                }
            }
            $r += ")"
            $result += $r + "`n"
         }
        Default {
            $result += $_ + "`n"
        }
    }
}
$result | Out-File -Encoding ascii -NoNewline $cheminFichierSortie