; LBA address of the loader
LOADER_SECTOR equ 0x2

; segment address of the loader
LOADER_SEGMENT equ 0x9000


; GDT (Global Descriptor Table)

; G (Granularity) 0 = Byte granularity, 1 = 4KB granularity
DESC_G equ 0b100000000000000000000000

; D/B (Default Operation Size) 0 = 16-bit, 1 = 32-bit
DESC_D equ 0b10000000000000000000000

; L (Long Mode) 0 = 32-bit code segment, 1 = 64-bit code segment
DESC_L equ 0b0000000000000000000000

; AVL (Available) available for system software use, just ignore this
DESC_AVL equ 0b000000000000000000000

; Limit (48~51 bits) Part 2
DESC_LIMIT_CODE equ 0b11110000000000000000
DESC_LIMIT_DATA equ 0b11110000000000000000
DESC_LIMIT_VIDEO equ 0b00000000000000001011

; P (Present) 0 = invalid segment, 1 = segment present
DESC_P equ 0b1000000000000000

; DPL (Descriptor Privilege Level) Ring 0~3
DESC_DPL_0 equ 0b000000000000000
DESC_DPL_1 equ 0b010000000000000
DESC_DPL_2 equ 0b100000000000000
DESC_DPL_3 equ 0b110000000000000

; S (Descriptor Type) 0 = system segment, 1 = code/data segment
DESC_S_CODE equ 0b1000000000000
DESC_S_DATA equ 0b1000000000000
DESC_S_SYS equ 0b0000000000000

; Type Segment type (code/data segment properties)
DESC_TYPE_CODE equ 0b100000000000
DESC_TYPE_DATA equ 0b001000000000

DESC_CODE_HIGH equ (0x00 << 24) + DESC_G + DESC_D + DESC_L + DESC_AVL + \
  DESC_LIMIT_CODE + DESC_P + DESC_DPL_0 + DESC_S_CODE + DESC_TYPE_CODE + 0x00
DESC_DATA_HIGH equ (0x00 << 24) + DESC_G + DESC_D + DESC_L + DESC_AVL + \
  DESC_LIMIT_DATA + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00
DESC_VIDEO_HIGH equ (0x00 << 24) + DESC_G + DESC_D + DESC_L + DESC_AVL + \
  DESC_LIMIT_VIDEO + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00


; Selector

; RPL (Requestor Privilege Level) Ring 0~3
RPL0 equ 0b00
RPL1 equ 0b01
RPL2 equ 0b10
RPL3 equ 0b11

; TI (Table Indicator) 0 = GDT, 1 = LDT
TI_GDT equ 0b000
TI_LDT equ 0b100


; Paging

; Page directory starts at 0x100000
PG_DIR equ 0x100000

; P (Present) 0 = invalid, 1 = present
PG_P equ 0b1

; RW (Read/Writte) 0 = Read, 1 = Read/Write
PG_RW_R equ 0b00
PG_RW_W equ 0b10

; US (User/Supervisor) 0 = Supervisor, 1 = User
PG_US_S equ 0b000
PG_US_U equ 0b100
