MBG Site Builder - full file set
================================
Extract these into your repo root C:\dev\mbg-project so that:
  src\...            merges into your Next.js src
  supabase\migrations\*.sql   (run these in Supabase SQL Editor)

RECOMMENDED extract (paste into PowerShell, bracket-path safe, overwrites):

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip='C:\Users\morew\Downloads\mbg-site-builder.zip'; $root='C:\dev\mbg-project'
  $a=[System.IO.Compression.ZipFile]::OpenRead($zip)
  foreach($e in $a.Entries){
   if($e.FullName.EndsWith('/')){continue}
   $dest=Join-Path $root ($e.FullName -replace '/','\')
   $dir=[System.IO.Path]::GetDirectoryName($dest)
   if(-not [System.IO.Directory]::Exists($dir)){[System.IO.Directory]::CreateDirectory($dir)|Out-Null}
   [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e,$dest,$true)
   Write-Host "[ok] $($e.FullName)"
  }
  $a.Dispose(); Write-Host "Done."

After extracting:
  1) Supabase SQL Editor: run 0001 -> 0002 -> 0003
  2) npx tsc --noEmit   (expect 0)
  3) npm run dev   ->  http://localhost:3000/?site=marinebiogroup

NOTE: src\middleware.ts will overwrite an existing one. If you already have
a middleware.ts (auth etc.), back it up and merge the host-routing logic.
