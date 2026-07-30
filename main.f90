program fp4500
    use iso_c_binding
    use libusb_bindings
    use fp4500_device
    implicit none

    type(c_ptr) :: ctx, dev
    integer(c_int) :: rc
    integer(c_int16_t) :: vendor_id, product_id

    vendor_id = int(z'05ba', c_int16_t)
    product_id = int(z'000a', c_int16_t)

    rc = libusb_init(ctx)

    if (rc /= 0) then
        print *, "libusb_init failed, code=", rc
        stop 1
    end if

    print *, "libusb initialized OK"

    dev = libusb_open_device_with_vid_pid(ctx, vendor_id, product_id)

    if (.not. c_associated(dev)) then
        ! device is not found, null value for dev
        print *, "Device not found."
        call libusb_exit(ctx)
        stop 1
    end if

    print *, "Device opened."

    rc = libusb_claim_interface(dev, 0)

    if (rc /= 0) then
        print *, "Cannot claim interface with device, exiting with error code: ", rc
        call libusb_close(dev)
        call libusb_exit(ctx)
        stop 1
    end if

    print *, "Successfully claimed USB interface."

    rc = init_device(dev)

    if (rc /= 0) then
        print *, "Device init failed, code=", rc
    else
        print *, "Device initialized and powered on."
    end if

    rc = libusb_release_interface(dev, 0)
    call libusb_close(dev)
    call libusb_exit(ctx)
    print *, "Cleaned up, exiting"

    print *, "Press enter to exit ..."
    read(*, *)
end program
