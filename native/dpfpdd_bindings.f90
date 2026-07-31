module dpfpdd_bindings
    use iso_c_binding
    implicit none

    integer(c_int), parameter :: DPFPDD_SUCCESS = 0
    integer(c_int), parameter :: DPFPDD_IMG_FMT_PIXEL_BUFFER = 0
    integer(c_int), parameter :: DPFPDD_IMG_PROC_DEFAULT = 0

    ! Mirrors DPFPDD_DEV_INFO's leading 'size' and 'name' fields exactly.
    ! 'reserved' just reserves enough trailing space to match (or exceed)
    ! the real C struct's total size, so the driver never writes past what
    ! we've actually allocated -- we just never read those trailing fields.
    type, bind(C) :: dpfpdd_dev_info_t
        integer(c_int) :: size
        character(kind=c_char) :: name(1024)
        integer(c_int8_t) :: reserved(432)
    end type dpfpdd_dev_info_t

    type, bind(C) :: dpfpdd_capture_param_t
        integer(c_int) :: size
        integer(c_int) :: image_fmt
        integer(c_int) :: image_proc
        integer(c_int) :: image_res
    end type dpfpdd_capture_param_t

    ! 'resolutions' is a flexible array in the real C struct (declared as
    ! resolutions[1], with more entries following in memory if resolution_cnt
    ! > 1). We over-allocate to 16 slots so we have room regardless.
    type, bind(C) :: dpfpdd_dev_caps_t
        integer(c_int) :: size
        integer(c_int) :: can_capture_image
        integer(c_int) :: can_stream_image
        integer(c_int) :: can_extract_features
        integer(c_int) :: can_match
        integer(c_int) :: can_identify
        integer(c_int) :: has_fp_storage
        integer(c_int) :: indicator_type
        integer(c_int) :: has_pwr_mgmt
        integer(c_int) :: has_calibration
        integer(c_int) :: piv_compliant
        integer(c_int) :: resolution_cnt
        integer(c_int) :: resolutions(16)
    end type dpfpdd_dev_caps_t

    type, bind(C) :: dpfpdd_image_info_t
        integer(c_int) :: size
        integer(c_int) :: width
        integer(c_int) :: height
        integer(c_int) :: res
        integer(c_int) :: bpp
    end type dpfpdd_image_info_t

    type, bind(C) :: dpfpdd_capture_result_t
        integer(c_int) :: size
        integer(c_int) :: success
        integer(c_int) :: quality
        integer(c_int) :: score
        type(dpfpdd_image_info_t) :: info
    end type dpfpdd_capture_result_t

    interface
        function dpfpdd_init() bind(C, name="dpfpdd_init") result(res)
            import :: c_int
            integer(c_int) :: res
        end function dpfpdd_init

        function dpfpdd_exit() bind(C, name="dpfpdd_exit") result(res)
            import :: c_int
            integer(c_int) :: res
        end function dpfpdd_exit

        function dpfpdd_query_devices(dev_cnt, dev_infos) &
            bind(C, name="dpfpdd_query_devices") result(res)
            import :: c_int, dpfpdd_dev_info_t
            integer(c_int) :: dev_cnt
            type(dpfpdd_dev_info_t) :: dev_infos(*)
            integer(c_int) :: res
        end function dpfpdd_query_devices

        function dpfpdd_open(dev_name, pdev) bind(C, name="dpfpdd_open") result(res)
            import :: c_char, c_ptr, c_int
            character(kind=c_char) :: dev_name(*)
            type(c_ptr) :: pdev
            integer(c_int) :: res
        end function dpfpdd_open

        function dpfpdd_close(dev) bind(C, name="dpfpdd_close") result(res)
            import :: c_ptr, c_int
            type(c_ptr), value :: dev
            integer(c_int) :: res
        end function dpfpdd_close

        function dpfpdd_get_device_capabilities(dev, dev_caps) &
            bind(C, name="dpfpdd_get_device_capabilities") result(res)
            import :: c_ptr, c_int, dpfpdd_dev_caps_t
            type(c_ptr), value :: dev
            type(dpfpdd_dev_caps_t) :: dev_caps
            integer(c_int) :: res
        end function dpfpdd_get_device_capabilities

        function dpfpdd_capture(dev, capture_parm, timeout_cnt, capture_result, &
            image_size, image_data) bind(C, name="dpfpdd_capture") result(res)
            import :: c_ptr, c_int, c_int8_t, dpfpdd_capture_param_t, dpfpdd_capture_result_t
            type(c_ptr), value :: dev
            type(dpfpdd_capture_param_t) :: capture_parm
            integer(c_int), value :: timeout_cnt
            type(dpfpdd_capture_result_t) :: capture_result
            integer(c_int) :: image_size
            integer(c_int8_t) :: image_data(*)
            integer(c_int) :: res
        end function dpfpdd_capture
    end interface

end module dpfpdd_bindings
