module fp4500_device
    use iso_c_binding
    use libusb_bindings
    implicit none

    integer(c_int16_t), parameter :: REG_HWSTAT = int(z'07', c_int16_t)
    integer(c_int16_t), parameter :: REG_MODE = int(z'4e', c_int16_t)
    integer(c_int16_t), parameter :: MODE_AWAIT_FINGER_ON = int(z'10', c_int16_t)
    integer(c_int16_t), parameter :: MODE_CAPTURE = int(z'20', c_int16_t)
    integer(c_int16_t), parameter :: MODE_AWAIT_FINGER_OFF = int(z'12', c_int16_t)

    integer(c_int8_t), parameter :: EP_INTR = int(z'81', c_int8_t)
    integer(c_int16_t), parameter :: IRQDATA_SCANPWR_ON = int(z'56aa', c_int16_t)
    integer(c_int16_t), parameter :: IRQDATA_FINGER_ON = int(z'0101', c_int16_t)
    integer(c_int16_t), parameter :: IRQDATA_FINGER_OFF = int(z'0200', c_int16_t)

    contains

        function reg_read(dev, reg, buf, length) result(res)
            type(c_ptr), value :: dev
            integer(c_int16_t), value :: reg
            integer(c_int8_t) :: buf(*)
            integer(c_int16_t), value :: length
            integer(c_int) :: res

            res = libusb_control_transfer(dev, int(z'c0', c_int8_t), int(z'04', c_int8_t), &
                reg, int(z'00', c_int16_t), buf, length, int(5000, c_int))
        end function

        function reg_write(dev, reg, buf, length) result(res)
            type(c_ptr), value :: dev
            integer(c_int16_t), value :: reg
            integer(c_int8_t) :: buf(*)
            integer(c_int16_t), value :: length
            integer(c_int) :: res

            res = libusb_control_transfer(dev, int(z'40', c_int8_t), int(z'04', c_int8_t), &
                reg, int(z'00', c_int16_t), buf, length, int(5000, c_int))
        end function

        function wait_irq(dev, want_type, timeout_ms) result(res)
            ! Declarations of data-types of parameters and the function return 'res'
            type(c_ptr), value :: dev
            integer(c_int16_t), value :: want_type
            integer(c_int), value :: timeout_ms
            integer(c_int) :: res

            ! Locally defined variables inside the scope of the function
            integer(c_int8_t) :: buf(64)
            integer(c_int) :: actual_length
            integer(c_int) :: transfer_rc
            integer(c_int32_t) :: type_code

            transfer_rc = libusb_bulk_transfer(dev, EP_INTR, buf, int(64, c_int), &
                actual_length, timeout_ms)

            if (transfer_rc /= 0) then
                res = transfer_rc
                return
            end if

            type_code = ishft(iand(int(buf(1), c_int32_t), 255), 8) + iand(int(buf(2), c_int32_t), &
            255)

            if (type_code == want_type) then
                res = 0
            else
                res = -1
            end if

        end function



end module
