#define RAM_BEGIN                       0x00000000
#define RAM_LEN                         0x00100000
#define RAM_END                         (RAM_BEGIN + RAM_LEN)

#define IRAM_BEGIN                      0x00001000
#define IRAM_LEN                        0x000FCE00
#define IRAM_END                        (IRAM_BEGIN + IRAM_LEN)

#define SRAM_BEGIN                      IRAM_END
#define SRAM_LEN                        (RAM_LEN - SRAM_BEGIN)
#define SRAM_END                        RAM_END

#define ABT_STACK_LEN           512
#define IRQ_STACK_LEN           1024
#define SVC_STACK_LEN           1024

#define HW_STACKS_LEN           (ABT_STACK_LEN + IRQ_STACK_LEN + SVC_STACK_LEN)

#define SIMTEST_CFG_LEN                 0x00000200
#define SIMTEST_CFG_BEGIN               (TTB_L2_BEGIN - SIMTEST_CFG_LEN)

// The MMU Level 1 page tables are in the top 16KB of boot ROM.
#define TTB_L1_BEGIN                    0xFFFF4000
#define TTB_L1_LEN                      0x4000

// The top 8KB of the system memory is reserved for MMU Level 2 page tables
#define TTB_L2_BEGIN                    0x000FE000
#define TTB_L2_LEN                      0x2000
#define TTB_L2_TABLE_SIZE               1024

#define STATUS_LEN                      0x4
#define STATUS_BEGIN                    (TTB_L2_BEGIN - STATUS_LEN)

#ifdef WGA_TEST_SOC_SIM_ONLY
#define SRAM_HEAP_END                   ( SIMTEST_CFG_BEGIN -4 )
#else
#define SRAM_HEAP_END                   ( STATUS_BEGIN -4 )
#endif

#define SPL_VEC_LEN                     (IRAM_BEGIN - RAM_BEGIN)
#define SRAM_HEAP_LEN                   (SRAM_HEAP_AREA)
MEMORY {
        TTB_L1  (r)  : ORIGIN = TTB_L1_BEGIN, LENGTH = TTB_L1_LEN
        TTB_L2  (r)  : ORIGIN = TTB_L2_BEGIN, LENGTH = TTB_L2_LEN
        SPL_VEC (x)  : ORIGIN = RAM_BEGIN,    LENGTH = SPL_VEC_LEN
        IRAM    (rx) : ORIGIN = IRAM_BEGIN,   LENGTH = IRAM_LEN
        SRAM    (rw) : ORIGIN = SRAM_BEGIN,   LENGTH = SRAM_LEN
}

ENTRY(__reset)

SECTIONS {
        _ram_start = .;


        SPECIAL_VECTORS : {
                KEEP(* (.text.spl_vectors))
        } >SPL_VEC =0

        text_start = IRAM_BEGIN;
        VECTORS : {
                KEEP(* (.text.vectors))
        } >IRAM

        FIQ_ISR : {
                KEEP(* (.fiq_isr))
        } >IRAM

        TX_INIT_AREA : {
                * (.text.tx_init)
        } >IRAM

        RESET : {
                * (.text.reset)
        } >IRAM

        BOOT_START : {
                * (.text.boot_start)
                * (.text.mmu_start)
                * (.text.core_init)
} >IRAM

        FASTPATH_CODE : {
                * (.text.fastpath)
                @@FASTPATH_OBJECTS@@
        } >IRAM


        CODE : {
                * (.text)
                * (.text.*)
        } >IRAM

        /* 4K alignments are for MMU */
        . = ALIGN(4096);
        text_end = .;


        RO_DATA ALIGN(4096) : {
                rodata_start  = .;
                * (.ro.boot_config)
                * (.rodata)
                * (.rodata.*)
                . = ALIGN(4096);
                rodata_end = .;
        } >IRAM

        DATA ALIGN(4096) : {
                data_start = .;
                * (.rw.boot_config)
                * (.data)
                * (.data.*)
                data_end = .;
        } >IRAM

        /*
         * if there are non-empty sections after BSS/STACK_HEAP then the linker
         * expands these sections in the image itself
         */
        BSS ALIGN(8) : {
                bss_start  = .;
                * (.bss)
                * (.bss.*)
                bss_end = .;
        } >IRAM

        HW_STACK ALIGN(16) : {
                /* for ThreadX initialization code */
                _stackbottom = .;
                . += HW_STACKS_LEN;
                /* for ThreadX initialization code */
                _sp =  .;
                _stacktop = .;
        } >IRAM

        /* all reclaim sections are individually aligned to 4 KiB, and are also
         * sized such that there are no holes in between reclaim sections
         */
        . = ALIGN(4096);
        _reclaim_start = .;

        .textrc1 ALIGN (4096) : {
                _rstart1      = .;
                _rstart_code1 = .;
                * (.textini1.*)
                * (.rodataini1.*)
                . = ALIGN(4096);
                _rend_code1   = .;
        } >IRAM

        .datarc1 ALIGN (4096) : {
                _rstart_data1 = .;
                * (.dataini1.*)
                . = ALIGN(4096);
                _rend_data1   = .;
                _rend1        = .;
        } >IRAM

        .textrc2 ALIGN (4096) : {
                _rstart2      = .;
                _rstart_code2 = .;
                * (.textini2.*)
                * (.rodataini2.*)
                . = ALIGN(4096);
                _rend_code2   = .;
        } >IRAM

        .datarc2 ALIGN (4096) : {
                _rstart_data2 = .;
                * (.dataini2.*)
                . = ALIGN(4096);
                _rend_data2   = .;
                _rend2        = .;
        } >IRAM

        .textrc3 ALIGN (4096) : {
                _rstart3      = .;
                _rstart_code3 = .;
                * (.textini3.*)
                * (.rodataini3.*)
                . = ALIGN(4096);
                _rend_code3   = .;
        } >IRAM

        .datarc3 ALIGN (4096) : {
                _rstart_data3 = .;
                * (.dataini3.*)
                . = ALIGN(4096);
                _rend_data3   = .;
                _rend3        = .;
        } >IRAM

        _reclaim_end = .;

        Load$$TTB_L2_AREA$$RO$$Base = .;

        _heap_start = .;
        _heap_end = SRAM_HEAP_END;


        /* for ThreadX initialization code */
        _end = .;

        /* for MMU tables */
        text_size     = text_end     - text_start;
        rodata_size   = rodata_end   - rodata_start;
        _rsize_code1  = _rend_code1  - _rstart_code1;
        _rsize_data1  = _rend_data1  - _rstart_data1;
        _rsize_code2  = _rend_code2  - _rstart_code2;
        _rsize_data2  = _rend_data2  - _rstart_data2;
        _rsize_code3  = _rend_code3  - _rstart_code3;
        _rsize_data3  = _rend_data3  - _rstart_data3;

#if defined(WGA_TEST_SOC_SIM_ONLY)
        SIMTEST_CFG SIMTEST_CFG_BEGIN : {
                Image$$SIMTEST_CFG_AREA$$Base  = .;
                . += SIMTEST_CFG_LEN;
                Image$$SIMTEST_CFG_AREA$$Limit = .;
        }

        /* Not used in simulation build */
        STATUS_AREA : {
                Image$$STATUS_AREA$$Base  = .;
                Image$$STATUS_AREA$$Limit = .;
        }
#else
        STATUS_AREA STATUS_BEGIN : {
                Image$$STATUS_AREA$$Base  = .;
                . += STATUS_LEN;
                Image$$STATUS_AREA$$Limit = .;
        }
#endif

        /* placeholder for MMU Level 2 page tables */
        TTB_L2_AREA (NOLOAD) : {
                sram_ttb_l2_tbl       = .;
                arm_periph_ttb_l2_tbl = . + TTB_L2_TABLE_SIZE;
        } >TTB_L2

        _ram_end = SRAM_END;
        _ram_free_size = _ram_end - _reclaim_end;

        /* MMU Level 1 page tables */
        TTB_L1_AREA (NOLOAD) : {
                Image$$TTB_L1_AREA$$Base  = .;
                Image$$TTB_L1_AREA$$Limit = . + TTB_L1_LEN;
        } >TTB_L1
}
