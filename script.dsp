select disk 0
convert gpt
create partition efi size = 500
format fs=fat32 quick
assign letter w
create partition primary
format fs=ntfs quick
assign letter c