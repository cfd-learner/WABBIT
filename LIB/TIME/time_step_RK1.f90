! ********************************
! 2D AMR prototype
! --------------------------------
!
! time step main function, RK1
!
! name: time_step_RK1.f90
! date: 23.09.2016
! author: msr
! version: 0.1
!
! ********************************

subroutine time_step_RK1(time)

    use module_params
    use module_blocks

    implicit none

    real(kind=rk), intent(inout)                :: time

    integer(kind=ik)                            :: dF, g, Bs, N, k, block_num
    real(kind=rk)                               :: dt

    g                       = blocks_params%number_ghost_nodes
    Bs                      = blocks_params%size_block

    N                       = size(blocks_params%active_list, dim=1)

    call calc_dt(dt)

    ! test
    !dt = 0.00017_rk

    time                    = time + dt
    ! last timestep fits in maximal time
    if (time >= params%time_max) then
        time = time - dt
        dt = params%time_max - time
        time = params%time_max
    end if

    ! check number of data fields
    if ( blocks_params%number_data_fields == 1 ) then
        ! single data field
        dF = blocks_params%number_data_fields

        !------------------------------
        ! first stage
        ! synchronize ghostnodes
        call synchronize_ghosts()

        do k = 1, N

            block_num                                   = blocks_params%active_list(k)
            blocks(block_num)%data_fields(dF)%data_old  = blocks(block_num)%data_fields(dF)%data_
            blocks(block_num)%data_fields(dF)%k1        = blocks(block_num)%data_fields(dF)%data_old
            ! RHS
            call RHS_2D_block(blocks(block_num)%data_fields(dF)%k1(:,:), blocks(block_num)%dx, blocks(block_num)%dy, g, Bs)

        end do

        !------------------------------
        ! final stage
        do k = 1, N

            block_num                                   = blocks_params%active_list(k)

            blocks(block_num)%data_fields(dF)%data_     = blocks(block_num)%data_fields(dF)%data_old + dt * ( blocks(block_num)%data_fields(dF)%k1 )

        end do

    else
        ! more than one data field
        ! to do

    end if

end subroutine time_step_RK1
