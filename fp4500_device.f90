module fp4500_device
    use iso_c_binding
    use libusb_bindings
    implicit none

    interface
        subroutine sleep_ms(ms) bind(C, name="Sleep")
            import :: c_int32_t
            integer(c_int32_t), value :: ms
        end subroutine
    end interface

    integer(c_int16_t), parameter :: REG_HWSTAT = int(z'07', c_int16_t)
    integer(c_int16_t), parameter :: REG_MODE = int(z'4e', c_int16_t)
    integer(c_int16_t), parameter :: MODE_AWAIT_FINGER_ON = int(z'10', c_int16_t)
    integer(c_int16_t), parameter :: MODE_CAPTURE = int(z'20', c_int16_t)
    integer(c_int16_t), parameter :: MODE_AWAIT_FINGER_OFF = int(z'12', c_int16_t)

    integer(c_int8_t), parameter :: EP_INTR = int(z'81', c_int8_t)
    integer(c_int16_t), parameter :: IRQDATA_SCANPWR_ON = int(z'56aa', c_int16_t)
    integer(c_int16_t), parameter :: IRQDATA_FINGER_ON = int(z'0101', c_int16_t)
    integer(c_int16_t), parameter :: IRQDATA_FINGER_OFF = int(z'0200', c_int16_t)

    integer(c_int8_t), parameter :: EP_DATA = int(z'82', c_int8_t)
    integer, parameter :: IMG_WIDTH = 384
    integer, parameter :: IMG_HEIGHT = 289
    integer, parameter :: IMG_SIZE = IMG_WIDTH * IMG_HEIGHT
    integer, parameter :: CAPTURE_HDRLEN = 64
    integer, parameter :: DATABLK_EXPECT = IMG_SIZE + CAPTURE_HDRLEN
    integer, parameter :: DATABLK_RQLEN = DATABLK_EXPECT + 384

    contains

        function reg_read(dev, reg, buf, length) result(res)
            type(c_ptr), value :: dev
            integer(c_int16_t), value :: reg
            integer(c_int8_t) :: buf(*)
            integer(c_int16_t), value :: length
            integer(c_int) :: res

            res = libusb_control_transfer(dev, int(z'c0', c_int8_t), int(z'0c', c_int8_t), &
                reg, int(z'00', c_int16_t), buf, length, int(5000, c_int))
        end function

        function reg_write(dev, reg, buf, length) result(res)
            type(c_ptr), value :: dev
            integer(c_int16_t), value :: reg
            integer(c_int8_t) :: buf(*)
            integer(c_int16_t), value :: length
            integer(c_int) :: res

            res = libusb_control_transfer(dev, int(z'40', c_int8_t), int(z'0c', c_int8_t), &
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
                print *, "wait_irq: bulk_transfer on EP_INTR failed, libusb code=", transfer_rc
                res = transfer_rc
                return
            end if

            type_code = ishft(iand(int(buf(1), c_int32_t), 255), 8) + iand(int(buf(2), c_int32_t), &
            255)

            print *, "wait_irq: received type=", type_code, " wanted=", want_type

            if (type_code == want_type) then
                res = 0
            else
                res = -1
            end if

        end function

        function disable_encryption(dev) result(res)
            type(c_ptr), value :: dev
            integer(c_int) :: res

            integer(c_int16_t) :: offsets(4)
            integer(c_int8_t) :: buf3(3)
            integer(c_int8_t) :: patch_buf(1)
            integer(c_int) :: rc
            integer :: i

            offsets(1) = int(z'510', c_int16_t)
            offsets(2) = int(z'62d', c_int16_t)
            offsets(3) = int(z'792', c_int16_t)
            offsets(4) = int(z'7f4', c_int16_t)

            do i = 1, 4
                rc = reg_read(dev, offsets(i), buf3, int(3, c_int16_t))

                if (buf3(1) == int(z'ff', c_int8_t) .and. &
                    iand(int(buf3(2), c_int32_t), int(z'0f', c_int32_t)) == int(z'07', c_int32_t) .and. &
                    buf3(3) == int(z'41', c_int8_t)) then

                    print *, "Encryption marker found at offset", offsets(i)
                    patch_buf(1) = int(iand(int(buf3(2), c_int32_t), int(z'ef', c_int32_t)), c_int8_t)
                    rc = reg_write(dev, int(offsets(i) + 1, c_int16_t), patch_buf, int(1, c_int16_t))
                    print *, "Patched, reg_write returned", rc

                    res = 0
                    return
                end if
            end do

            print *, "No encryption marker found (device may already have it disabled)"
            res = 0
        end function

        function power_up(dev) result(res)
            type(c_ptr), value :: dev
            integer(c_int) :: res

            integer(c_int8_t) :: hwstat_buf(1)
            integer(c_int) :: rc
            integer :: attempt, i
            do attempt = 1, 3
                do i = 1, 100
                    rc = reg_read(dev, REG_HWSTAT, hwstat_buf, int(1, c_int16_t))
                    hwstat_buf(1) = ior(hwstat_buf(1), int(z'80', c_int8_t))
                    rc = reg_write(dev, REG_HWSTAT, hwstat_buf, int(1, c_int16_t))
                    rc = reg_read(dev, REG_HWSTAT, hwstat_buf, int(1, c_int16_t))

                    if(iand(int(hwstat_buf(1), c_int32_t), int(z'80', c_int32_t)) == 0) then
                        exit
                    end if
                end do

                rc = wait_irq(dev, IRQDATA_SCANPWR_ON, int(300, c_int))

                if (rc == 0) then
                    res = 0
                    return
                end if

                print *, "power_up: attempt", attempt, "did not see SCANPWR_ON, retrying"
            end do

            res = -1
        end function

        function init_device(dev) result(res)
            type(c_ptr), value :: dev
            integer(c_int) :: res

            integer(c_int8_t) :: hwstat_buf(1)
            integer(c_int8_t) :: hwstat
            integer(c_int) :: rc

            rc = reg_read(dev, REG_HWSTAT, hwstat_buf, int(1, c_int16_t))
            hwstat = hwstat_buf(1)

            if (iand(int(hwstat, c_int32_t), int(z'84', c_int32_t)) == int(z'84', c_int32_t)) then
                hwstat_buf(1) = iand(hwstat, int(z'0f', c_int8_t))
                rc = reg_write(dev, REG_HWSTAT, hwstat_buf, int(1, c_int16_t))
                call sleep_ms(int(50, c_int32_t))
            end if

            if (iand(int(hwstat, c_int32_t), int(z'80', c_int32_t)) == 0) then
                hwstat_buf(1) = ior(hwstat, int(z'80', c_int8_t))
                rc = reg_write(dev, REG_HWSTAT, hwstat_buf, int(1, c_int16_t))
            end if

            rc = disable_encryption(dev)

            rc = reg_read(dev, REG_HWSTAT, hwstat_buf, int(1, c_int16_t))
            hwstat_buf(1) = iand(hwstat_buf(1), int(z'0f', c_int8_t))
            rc = reg_write(dev, REG_HWSTAT, hwstat_buf, int(1, c_int16_t))

            res = power_up(dev)

        end function

        function capture_image(dev, out_path) result(res)
            type(c_ptr), value :: dev
            character(len=*), intent(in) :: out_path
            integer(c_int) :: res

            integer(c_int8_t) :: mode_buf(1)
            integer(c_int8_t), allocatable :: raw(:)
            integer(c_int8_t), allocatable :: fixed(:)
            integer(c_int) :: rc, actual_length
            integer :: hdr_skip, x, y, src_x, src_y, src_idx, pix, unit

            mode_buf(1) = -1
            rc = reg_read(dev, REG_MODE, mode_buf, int(1, c_int16_t))
            print *, "REG_MODE before any write: rc=", rc, " value=", mode_buf(1)

            mode_buf(1) = MODE_AWAIT_FINGER_ON
            rc = reg_write(dev, REG_MODE, mode_buf, int(1, c_int16_t))
            print *, "reg_write(MODE_AWAIT_FINGER_ON) returned", rc

            mode_buf(1) = -1
            rc = reg_read(dev, REG_MODE, mode_buf, int(1, c_int16_t))
            print *, "REG_MODE immediately after write: rc=", rc, " value=", mode_buf(1)

            call sleep_ms(int(50, c_int32_t))

            mode_buf(1) = -1
            rc = reg_read(dev, REG_MODE, mode_buf, int(1, c_int16_t))
            print *, "REG_MODE after 50ms delay: rc=", rc, " value=", mode_buf(1)

            print *, "Waiting for finger (10s timeout for debugging)..."
            rc = wait_irq(dev, IRQDATA_FINGER_ON, int(10000, c_int))
            if (rc /= 0) then
                print *, "Did not see finger-on interrupt, code=", rc
                res = rc
                return
            end if

            print *, "Finger detected, capturing..."
            mode_buf(1) = MODE_CAPTURE
            rc = reg_write(dev, REG_MODE, mode_buf, int(1, c_int16_t))

            allocate(raw(DATABLK_RQLEN))
            rc = libusb_bulk_transfer(dev, EP_DATA, raw, int(DATABLK_RQLEN, c_int), &
                actual_length, int(5000, c_int))

            if (rc /= 0) then
                print *, "Bulk image read failed, code=", rc
                res = rc
                deallocate(raw)
                return
            end if

            if (actual_length == IMG_SIZE) then
                print *, "Got image with no header"
                hdr_skip = 0
            else if (actual_length /= DATABLK_EXPECT) then
                print *, "Unexpected transfer length: ", actual_length
                res = -1
                deallocate(raw)
                return
            else
                hdr_skip = CAPTURE_HDRLEN
            end if

            ! Sensor reports frames vertically + horizontally flipped with
            ! inverted colors relative to a normal top-down grayscale image.
            allocate(fixed(IMG_SIZE))

            do y = 1, IMG_HEIGHT
                do x = 1, IMG_WIDTH
                    src_y = IMG_HEIGHT - y + 1
                    src_x = IMG_WIDTH - x + 1
                    src_idx = hdr_skip + (src_y - 1) * IMG_WIDTH + src_x
                    pix = iand(int(raw(src_idx), c_int32_t), 255)
                    fixed((y - 1) * IMG_WIDTH + x) = int(255 - pix, c_int8_t)
                end do
            end do

            deallocate(raw)

            ! Write the PGM header as plain text first...
            open(newunit=unit, file=out_path, status='replace', action='write', form='formatted')
            write(unit, '(A)') 'P5'
            write(unit, '(I0,1X,I0)') IMG_WIDTH, IMG_HEIGHT
            write(unit, '(A)') '255'
            close(unit)

            ! ...then reopen in binary stream mode to append the raw pixel bytes.
            open(newunit=unit, file=out_path, status='old', action='write', &
                form='unformatted', access='stream', position='append')
            write(unit) fixed
            close(unit)

            deallocate(fixed)

            print *, "Wrote ", out_path

            mode_buf(1) = MODE_AWAIT_FINGER_OFF
            rc = reg_write(dev, REG_MODE, mode_buf, int(1, c_int16_t))
            rc = wait_irq(dev, IRQDATA_FINGER_OFF, int(0, c_int))
            print *, "Finger lifted"

            res = 0
        end function

end module
