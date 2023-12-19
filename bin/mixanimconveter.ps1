$cheminFichier = $args[0]
$cheminFichierSortie = $args[1]

$position_regex = "\((.*)\)"

$result = ""
$contenu = Get-Content -Path $cheminFichier
foreach ($ligne in $contenu) {
    switch ($ligne) {
        { $_.StartsWith("tracks/1/keys") } { 
            $m = $ligne -match $position_regex
            $values = $Matches[1] -split ','
            $r = "tracks/1/keys = PackedFloat32Array("
            for ($i = 0; $i -lt $values.Count; $i += 6) {
                $x = [float]$values[$i+2] 
                $y = [float]$values[$i+3]
                $z = [float]$values[$i+4]
                $w = [float]$values[$i+5]
                $q_orig = [System.Numerics.Quaternion]::new($x, $y, $z, $w)
                $q_new = [System.Numerics.Quaternion]::CreateFromYawPitchRoll(1.5708, 0, 0)
                $q = [System.Numerics.Quaternion]::Concatenate($q_orig, $q_new)
                $q = [System.Numerics.Quaternion]::Normalize($q)
           
                $r += $values[$i] # time
                $r += ","
                $r += $values[$i+1] # ?
                $r += ", "
                $r += $q.x # x
                $r += ", "
                $r += $q.y # y
                $r += ", "
                $r += $q.z # z
                $r += ", "
                $r += $q.w # w
                if (($i+6) -lt $values.Count) {
                    $r += ","
                }
               
            }
            $r += ")"
            $result += $r.replace('E', 'e') + "`n"
         }
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