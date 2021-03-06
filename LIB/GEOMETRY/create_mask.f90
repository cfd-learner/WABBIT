!> \file
!> \callgraph
! ********************************************************************************************
! WABBIT
! ============================================================================================
!> \name create_mask.f90
!> \version 0.5
!> \author engels, sm
!
!> \brief  \n
!> \note 
!
!> \details
!! input:    - params, mask, center, spacing of block \n
!! output:   - mask term for every grid point of this block
!!
!!
!! = log ======================================================================================
!! \n
!! 27/06/17 - create \n
!! 21/11/17 - each geometry gets its own subroutine - this subroutine acts as wrapper
!
! ********************************************************************************************

subroutine create_mask_2D(params, mask, x0, dx, Bs, g )

    use module_params
    use module_precision

    implicit none

    !> user defined parameter structure
    type (type_params), intent(in)                            :: params
    !> mask term for every grid point of this block
    real(kind=rk), dimension(2*g+Bs, 2*g+Bs), intent(out)     :: mask
    !> spacing and origin of block
    real(kind=rk), dimension(2), intent(in)                   :: x0, dx
    ! grid
    integer(kind=ik), intent(in)                              :: Bs, g

!---------------------------------------------------------------------------------------------
! variables initialization

    select case(params%geometry)

        case('cylinder')
            call cylinder(params, mask, x0, dx, Bs, g)
        case('two_cylinders')
            call two_cylinders(params, mask, x0, dx, Bs, g)
        case default
            write(*,'(80("_"))')
            write(*,*) "ERROR: geometry for VPM is unknown"
            write(*,*) params%geometry
            stop
    end select

end subroutine create_mask_2D

subroutine create_mask_3D(params, mask, x0, dx, Bs, g )

    use module_params
    use module_precision

    implicit none

    !> user defined parameter structure
    type (type_params), intent(in)                                    :: params
    !> mask term for every grid point of this block
    real(kind=rk), dimension(2*g+Bs, 2*g+Bs, 2*g+Bs), intent(inout)   :: mask
    !> spacing and origin of block
    real(kind=rk), dimension(3), intent(in)                           :: x0, dx
    ! grid
    integer(kind=ik), intent(in)                                      :: Bs, g

!---------------------------------------------------------------------------------------------
! variables initialization
!---------------------------------------------------------------------------------------------
! main body

    select case(params%geometry)

        case('sphere')
            call sphere(params, mask, x0, dx, Bs, g)
        case default
            write(*,'(80("_"))')
            write(*,*) "ERROR: geometry for VPM is unknown"
            write(*,*) params%geometry
            stop
    end select

end subroutine create_mask_3D

subroutine smoothstep(f,x,t,h)
!-------------------------------------------------------------------------------
!> This subroutine returns the value f of a smooth step function \n
!> The sharp step function would be 1 if x<=t and 0 if x>t \n
!> h is the semi-size of the smoothing area, so \n
!> f is 1 if x<=t-h \n
!> f is 0 if x>t+h \n
!> f is variable (smooth) in between
!-------------------------------------------------------------------------------
    use module_precision
    
    implicit none
    real(kind=rk), intent(out) :: f
    real(kind=rk), intent(in)  :: x,t,h

        !-------------------------------------------------
        ! cos shaped smoothing (compact in phys.space)
        !-------------------------------------------------
        if (x<=t-h) then
          f = 1.0_rk
        elseif (((t-h)<x).and.(x<(t+h))) then
          f = 0.5_rk * (1.0_rk + dcos((x-t+h) * pi / (2.0_rk*h)) )
        else
          f = 0.0_rk
        endif
  
end subroutine smoothstep
