module libusb_bindings
    use iso_c_binding
    implicit none

    interface
        ! int libusb_init(libusb_context **ctx);
        function libusb_init(ctx) bind(C, name="libusb_init") result(res)
            import :: c_int, c_ptr
            type(c_ptr) :: ctx
            integer(c_int) :: res
        end function

        ! void libusb_exit(libusb_context, *ctx);
        subroutine libusb_exit(ctx) bind(C, name="libusb_exit")
            import :: c_ptr
            type(c_ptr), value :: ctx
        end subroutine

        ! int libusb_claim_interface(lib_usb_device_handle_dev *dev, int interface_number);
        function libusb_claim_interface(dev, interface_number) bind(C, name="libusb_claim_interface") result (res)
            import :: c_int, c_ptr
            type(c_ptr), value :: dev
            integer(c_int), value :: interface_number
            integer(c_int) :: res
        end function

        function libusb_release_interface(dev, interface_number) bind(C, name="libusb_release_interface") result(res)
            import :: c_int, c_ptr
            type(c_ptr), value :: dev
            integer(c_int), value :: interface_number
            integer(c_int) :: res
        end function

        subroutine libusb_close(dev) bind(C, name="libusb_close")
            import :: c_ptr
            type(c_ptr), value :: dev
        end subroutine

        function libusb_control_transfer(dev, request_type, bRequest, &
            wValue, wIndex, datum, wLength, &
            timeout) bind(C, name="libusb_control_transfer") result(res)
            import :: c_ptr, c_int8_t, c_int16_t, c_int
            type(c_ptr), value :: dev
            integer(c_int8_t), value :: request_type
            integer(c_int8_t), value :: bRequest
            integer(c_int16_t), value :: wValue
            integer(c_int16_t), value :: wIndex
            integer(c_int8_t) :: datum(*)
            integer(c_int16_t), value :: wLength
            integer(c_int), value :: timeout
            integer(c_int) :: res
        end function

        function libusb_open_device_with_vid_pid(ctx, vendor_id, &
            product_id) bind(C, name="libusb_open_device_with_vid_pid") result(res)
            import :: c_ptr, c_int16_t
            type(c_ptr), value :: ctx
            integer(c_int16_t), value :: vendor_id
            integer(c_int16_t), value :: product_id
            type(c_ptr) :: res
        end function

        function libusb_bulk_transfer(dev, endpoint, buffer, length, &
            actual_length, timeout) bind(C, name="libusb_bulk_transfer") result(res)
            import ::  c_int8_t, c_int, c_ptr
            type(c_ptr), value :: dev
            integer(c_int8_t), value :: endpoint
            integer(c_int8_t) :: buffer(*)
            integer(c_int), value :: length
            integer(c_int) :: actual_length
            integer(c_int), value :: timeout
            integer(c_int) :: res
        end function

    end interface

end module libusb_bindings
