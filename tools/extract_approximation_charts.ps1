# Reproduce the unedited teacher graphs. Original Word files remain read-only.
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$courseRoot = [System.IO.Path]::GetDirectoryName($projectRoot)
$sourcePath = Join-Path $courseRoot '5a/МУ-3прибл.cПрил.Fig.1-3.docx'
$assetDir = Join-Path $projectRoot 'assets/approximation'
New-Item -ItemType Directory -Force -Path $assetDir | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing
$archive = [System.IO.Compression.ZipFile]::OpenRead($sourcePath)
try {
    foreach ($number in @(10,41,42,43)) {
        $entry = $archive.GetEntry("word/media/image$number.emf")
        $emfPath = Join-Path $assetDir "chart$number.emf"
        $inputStream = $entry.Open()
        $outputStream = [System.IO.File]::Create($emfPath)
        try { $inputStream.CopyTo($outputStream) } finally { $inputStream.Dispose(); $outputStream.Dispose() }
        $sourceImage = [System.Drawing.Image]::FromFile($emfPath)
        try {
            $imageWidth = 2400
            $imageHeight = [int]($sourceImage.Height * $imageWidth / $sourceImage.Width)
            $bitmap = New-Object System.Drawing.Bitmap $imageWidth,$imageHeight
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.Color]::White)
                $graphics.DrawImage($sourceImage,0,0,$imageWidth,$imageHeight)
                $bitmap.Save((Join-Path $assetDir "chart$number.png"),[System.Drawing.Imaging.ImageFormat]::Png)
            } finally { $graphics.Dispose(); $bitmap.Dispose() }
        } finally { $sourceImage.Dispose() }
    }
} finally { $archive.Dispose() }
