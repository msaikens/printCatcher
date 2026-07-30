program fp4500_sdk
    use iso_c_binding
    use dpfpdd_bindings
    implicit none

    integer(c_int) :: rc
    integer(c_int) :: dev_cnt
    type(dpfpdd_dev_info_t) :: dev_infos(4)
    type(c_ptr) :: dev
    type(dpfpdd_capture_param_t) :: capture_parm
    type(dpfpdd_capture_result_t) :: capture_result
    integer(c_int) :: image_size
    integer(c_int8_t), allocatable :: image_data(:)
    integer :: unit, i
    character(len=256) :: out_path
    type(dpfpdd_dev_caps_t) :: dev_caps

    rc = dpfpdd_init()
    if (rc /= 0) then
        print *, "dpfpdd_init failed, code=", rc
        print *, "Press enter to exit ..."
        read(*, *)
        stop 1
    end if
    print *, "dpfpdd initialized"

    dev_cnt = 4
    do i = 1, 4
        dev_infos(i)%size = int(c_sizeof(dev_infos(i)), c_int)
    end do

    rc = dpfpdd_query_devices(dev_cnt, dev_infos)
    if (rc /= 0) then
        print *, "dpfpdd_query_devices failed, code=", rc
        print *, "Press enter to exit ..."
        read(*, *)
        stop 1
    end if
    print *, "Found", dev_cnt, "device(s)"

    if (dev_cnt < 1) then
        print *, "No reader found"
        print *, "Press enter to exit ..."
        read(*, *)
        stop 1
    end if

    rc = dpfpdd_open(dev_infos(1)%name, dev)
    if (rc /= 0) then
        print *, "dpfpdd_open failed, code=", rc
        print *, "Press enter to exit ..."
        read(*, *)
        stop 1
    end if
    print *, "Reader opened"

    dev_caps%size = int(c_sizeof(dev_caps), c_int)
    rc = dpfpdd_get_device_capabilities(dev, dev_caps)
    if (rc /= 0) then
        print *, "dpfpdd_get_device_capabilities failed, code=", rc
        print *, "Press enter to exit ..."
        read(*, *)
        stop 1
    end if
    print *, "resolution_cnt=", dev_caps%resolution_cnt, " first resolution=", dev_caps%resolutions(1)

    capture_parm%size = int(c_sizeof(capture_parm), c_int)
    capture_parm%image_fmt = DPFPDD_IMG_FMT_PIXEL_BUFFER
    capture_parm%image_proc = DPFPDD_IMG_PROC_DEFAULT
    capture_parm%image_res = dev_caps%resolutions(1)

    capture_result%size = int(c_sizeof(capture_result), c_int)

    allocate(image_data(500000))
    image_size = 500000

    print *, "Waiting for finger..."
    rc = dpfpdd_capture(dev, capture_parm, int(-1, c_int), capture_result, image_size, image_data)

    if (rc /= 0) then
        print *, "dpfpdd_capture failed, code=", rc
        rc = dpfpdd_close(dev)
        rc = dpfpdd_exit()
        print *, "Press enter to exit ..."
        read(*, *)
        stop 1
    end if

    print *, "Capture success=", capture_result%success, " quality=", capture_result%quality
    print *, "Image", capture_result%info%width, "x", capture_result%info%height, &
        " bpp=", capture_result%info%bpp
    print *, "image_size=", image_size

    out_path = "capture_sdk.pgm"

    open(newunit=unit, file=trim(out_path), status='replace', action='write', form='formatted')
    write(unit, '(A)') 'P5'
    write(unit, '(I0,1X,I0)') capture_result%info%width, capture_result%info%height
    write(unit, '(A)') '255'
    close(unit)

    open(newunit=unit, file=trim(out_path), status='old', action='write', &
        form='unformatted', access='stream', position='append')
    write(unit) image_data(1:image_size)
    close(unit)

    print *, "Wrote ", trim(out_path)

    rc = dpfpdd_close(dev)
    rc = dpfpdd_exit()
    print *, "Done"

    print *, "Press enter to exit ..."
    read(*, *)
end program fp4500_sdk
