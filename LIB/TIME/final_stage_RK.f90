!> \file
!> \callgraph
! ********************************************************************************************
! WABBIT
! ============================================================================================
!> \name final_stage_RK.f90
!> \version 0.5
!> \author sm
!
!> \brief final stage of Runge-Kutta time step. Gives back data field  at t+dt
!
!>
!! input:    
!!           - params
!!           - heavy data
!!           - time step dt
!!           - coefficients for Runge Kutta
!! 
!! output:
!!           - hvy_work 
!!
!! butcher table
!!
!! |   |            |
!! |---|------------|
!! |c1 | a11 0     0|
!! |c2 | a21 a22   0|
!! |c3 | a31 a32 a33|
!! |0  | b1  b2   b3|
!!
!!
!! = log ======================================================================================
!! \n
!! 23/05/17 - create
!
!**********************************************************************************************

subroutine final_stage_RK(params, dt, hvy_work, hvy_block, hvy_active, hvy_n, rk_coeffs)

!---------------------------------------------------------------------------------------------
! modules

!---------------------------------------------------------------------------------------------
! variables

    implicit none

    !> user defined parameter structure
    type (type_params), intent(in)      :: params
    !> dt
    real(kind=rk), intent(in)           :: dt
    !> heavy data array - block data
    real(kind=rk), intent(inout)        :: hvy_block(:, :, :, :, :)
    !> heavy work data array - block data
    real(kind=rk), intent(inout)        :: hvy_work(:, :, :, :, :)

    !> list of active blocks (heavy data)
    integer(kind=ik), intent(in)        :: hvy_active(:)
    !> number of active blocks (heavy data)
    integer(kind=ik), intent(in)        :: hvy_n


    ! array containing Runge-Kutta coefficients
    real(kind=rk), intent(in)           :: rk_coeffs(:,:)

    ! loop variables
    integer(kind=ik)                    :: dF, k, j, N_dF

!---------------------------------------------------------------------------------------------
! interfaces

!---------------------------------------------------------------------------------------------
! variables initialization

    N_dF  = params%number_data_fields

!---------------------------------------------------------------------------------------------
! main body

    select case(params%physics_type)

        case('2D_convection_diffusion')
            ! loop over all datafields
            do dF = 2, N_dF+1
                ! loop over all active heavy data blocks
                do k = 1, hvy_n
                    !u_n = u_n +...
                    hvy_block( :, :, :, dF, hvy_active(k)) = hvy_work( :, :, :, (dF-2)*5+1, hvy_active(k) )

                    do j = 2, size(rk_coeffs, 2) 
                        if ( abs(rk_coeffs(size(rk_coeffs, 1),j)) < 1e-8_rk) then
                        else
                            ! ... dt*(b1*k1 + b2*k2+ ..)
                            ! rk_coeffs(size(rk_coeffs,1)) , since rk_coeffs is symmetric and we want to access last line,  e.g. b1 = butcher(last line,2)
                            hvy_block( :, :, :, dF, hvy_active(k)) = hvy_block( :, :, :, dF, hvy_active(k)) + dt*rk_coeffs(size(rk_coeffs,1),j) * hvy_work( :, :, :, (dF-2)*5+j, hvy_active(k))
                        end if
                    end do
                end do
            end do

        case('2D_navier_stokes')
                ! loop over all active heavy data blocks
                do k = 1, hvy_n
                    !u_n = u_n +...
                    hvy_block( :, :, :, 2:N_dF+1, hvy_active(k)) = hvy_work( :, :, :, 1:N_dF, hvy_active(k) )

                    do j = 2, size(rk_coeffs, 2) 
                        if ( abs(rk_coeffs(size(rk_coeffs, 1),j)) < 1e-8_rk) then
                        else
                            ! ... dt*(b1*k1 + b2*k2+ ..)
                            ! rk_coeffs(size(rk_coeffs,1)) , since rk_coeffs is symmetric and we want to access last line,  e.g. b1 = butcher(last line,2)
                            hvy_block( :, :, :, 2:N_dF+1, hvy_active(k)) = hvy_block( :, :, :, 2:N_dF+1, hvy_active(k)) + dt*rk_coeffs(size(rk_coeffs,1),j) * hvy_work( :, :, :, (j-1)*N_dF+1:j*N_dF, hvy_active(k))
                        end if
                    end do
                end do

        case('3D_convection_diffusion')
            ! loop over all datafields
            do dF = 2, N_dF+1
                ! loop over all active heavy data blocks
                do k = 1, hvy_n
                    !u_n = u_n +...
                    hvy_block( :, :, :, dF, hvy_active(k)) = hvy_work( :, :, :, (dF-2)*5+1, hvy_active(k) )

                    do j = 2, size(rk_coeffs, 2) 
                        if ( abs(rk_coeffs(size(rk_coeffs, 1),j)) < 1e-8_rk) then
                        else
                            ! ... dt*(b1*k1 + b2*k2+ ..)
                            ! rk_coeffs(size(rk_coeffs,1)) , since rk_coeffs is symmetric and we want to access last line,  e.g. b1 = butcher(last line,2)
                            hvy_block( :, :, :, dF, hvy_active(k)) = hvy_block( :, :, :, dF, hvy_active(k)) + dt*rk_coeffs(size(rk_coeffs,1),j) * hvy_work( :, :, :, (dF-2)*5+j, hvy_active(k))
                        end if
                    end do
                end do
            end do

        case('3D_navier_stokes')
            ! loop over all active heavy data blocks
                do k = 1, hvy_n
                    !u_n = u_n +...
                    hvy_block( :, :, :, 2:N_dF+1, hvy_active(k)) = hvy_work( :, :, :, 1:N_dF, hvy_active(k) )

                    do j = 2, size(rk_coeffs, 2) 
                        if ( abs(rk_coeffs(size(rk_coeffs, 1),j)) < 1e-8_rk) then
                        else
                            ! ... dt*(b1*k1 + b2*k2+ ..)
                            ! rk_coeffs(size(rk_coeffs,1)) , since rk_coeffs is symmetric and we want to access last line,  e.g. b1 = butcher(last line,2)
                            hvy_block( :, :, :, 2:N_dF+1, hvy_active(k)) = hvy_block( :, :, :, 2:N_dF+1, hvy_active(k)) + dt*rk_coeffs(size(rk_coeffs,1),j) * hvy_work( :, :, :, (j-1)*N_dF+1:j*N_dF, hvy_active(k))
                        end if
                    end do
                end do

        case('2D_advection')
            ! loop over all datafields
            do dF = 2, N_dF+1
                ! loop over all active heavy data blocks
                do k = 1, hvy_n
                    !u_n = u_n +...
                    hvy_block( :, :, :, dF, hvy_active(k)) = hvy_work( :, :, :, (dF-2)*5+1, hvy_active(k) )

                    do j = 2, size(rk_coeffs, 2) 
                        if ( abs(rk_coeffs(size(rk_coeffs, 1),j)) < 1e-8_rk) then
                        else
                            ! ... dt*(b1*k1 + b2*k2+ ..)
                            ! rk_coeffs(size(rk_coeffs,1)) , since rk_coeffs is symmetric and we want to access last line,  e.g. b1 = butcher(last line,2)
                            hvy_block( :, :, :, dF, hvy_active(k)) = hvy_block( :, :, :, dF, hvy_active(k)) + dt*rk_coeffs(size(rk_coeffs,1),j) * hvy_work( :, :, :, (dF-2)*5+j, hvy_active(k))
                        end if
                    end do
                end do
            end do

        case default
            write(*,'(80("_"))')
            write(*,*) "ERROR: physics type is unknown"
            write(*,*) params%physics_type
            stop

    end select


end subroutine final_stage_RK
