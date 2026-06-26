# WhatsApp Bridge Starter
$env:PATH += ";E:\TDM-GCC-64\bin"
$env:CGO_ENABLED = "1"
Set-Location "E:\whatsapp-mcp\whatsapp-bridge"
go run main.go
