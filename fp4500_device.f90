module fp4500_device
    use iso_c_binding
    use libusb_bindings
    implicit none

    integer(c_int16_t), parameter :: REG_HWSTAT = int(z'07', c_int16_t)
    integer(c_int16_t), parameter :: REG_MODE = int(z'4e', c_int16_t)
    integer(c_int16_t), parameter :: MODE_AWAIT_FINGER_ON = int(z'10', c_int16_t)
    integer(c_int16_t), parameter :: MODE_CAPTURE = int(z'20', c_int16_t)
    integer(c_int16_t), parameter :: MODE_AWAIT_FINGER_OFF = int(z'12', c_int16_t)

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

end module
