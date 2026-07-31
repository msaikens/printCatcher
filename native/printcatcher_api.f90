module printcatcher_api
    use iso_c_binding
    use dpfpdd_bindings
    implicit none

    type(c_ptr), save :: g_dev = c_null_ptr

contains

    function pc_init() bind(C, name="pc_init") result(res)
        integer(c_int) :: res
        res = dpfpdd_init()
    end function pc_init

    function pc_open() bind(C, name="pc_open") result(res)
        integer(c_int) :: res
        integer(c_int) :: dev_cnt
        type(dpfpdd_dev_info_t) :: dev_infos(4)
        integer :: i

        dev_cnt = 4
        do i = 1, 4
            dev_infos(i)%size = int(c_sizeof(dev_infos(i)), c_int)
        end do

        res = dpfpdd_query_devices(dev_cnt, dev_infos)
        if (res /= 0) return

        if (dev_cnt < 1) then
            res = -1
            return
        end if

        res = dpfpdd_open(dev_infos(1)%name, g_dev)
    end function pc_open

    ! Captures one fingerprint image into 'buffer' (caller-allocated,
    ! buffer_len bytes). Blocks until a finger is presented or timeout_ms
    ! elapses (pass -1 for no timeout). On success, out_width/out_height/
    ! out_bpp describe the image and out_image_size is how many bytes of
    ! 'buffer' were actually written.
    function pc_capture(buffer, buffer_len, timeout_ms, &
            out_width, out_height, out_bpp, out_image_size) &
            bind(C, name="pc_capture") result(res)
        integer(c_int8_t) :: buffer(*)
        integer(c_int), value :: buffer_len
        integer(c_int), value :: timeout_ms
        integer(c_int) :: out_width
        integer(c_int) :: out_height
        integer(c_int) :: out_bpp
        integer(c_int) :: out_image_size
        integer(c_int) :: res

        type(dpfpdd_capture_param_t) :: capture_parm
        type(dpfpdd_capture_result_t) :: capture_result
        type(dpfpdd_dev_caps_t) :: dev_caps
        integer(c_int) :: image_size

        dev_caps%size = int(c_sizeof(dev_caps), c_int)
        res = dpfpdd_get_device_capabilities(g_dev, dev_caps)
        if (res /= 0) return

        capture_parm%size = int(c_sizeof(capture_parm), c_int)
        capture_parm%image_fmt = DPFPDD_IMG_FMT_PIXEL_BUFFER
        capture_parm%image_proc = DPFPDD_IMG_PROC_DEFAULT
        capture_parm%image_res = dev_caps%resolutions(1)

        capture_result%size = int(c_sizeof(capture_result), c_int)
        image_size = buffer_len

        res = dpfpdd_capture(g_dev, capture_parm, timeout_ms, capture_result, image_size, buffer)
        if (res /= 0) return

        out_width = capture_result%info%width
        out_height = capture_result%info%height
        out_bpp = capture_result%info%bpp
        out_image_size = image_size
    end function pc_capture

    function pc_close() bind(C, name="pc_close") result(res)
        integer(c_int) :: res
        res = dpfpdd_close(g_dev)
        g_dev = c_null_ptr
    end function pc_close

    function pc_exit() bind(C, name="pc_exit") result(res)
        integer(c_int) :: res
        res = dpfpdd_exit()
    end function pc_exit

end module printcatcher_api
