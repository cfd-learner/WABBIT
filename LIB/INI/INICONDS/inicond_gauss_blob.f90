!> \file
!> \callgraph
! ********************************************************************************************
! WABBIT
! ============================================================================================
!> \name inicond_gauss_blob.f90
!> \version 0.5
!> \author engels, msr
!
!> \brief initialize gauss pulse for 2D case \n
!> \note field phi is 3D, but third dimension is not used
!
!> \details
!! input:    - params \n
!! output:   - light and heavy data arrays \n
!!
!!
!! = log ======================================================================================
!! \n
!! 04/11/16
!!          - switch to v0.4
!!
!! 26/01/17
!!          - use process rank from params struct
!!          - use v0.5 hvy data array
!!
!! 04/04/17
!!          - rewrite to work only on blocks, no large datafield required
!
! ********************************************************************************************

subroutine inicond_gauss_blob( params, u, x0, dx )

    implicit none

    !> user defined parameter structure
    type (type_params), intent(inout)    :: params
    !> actual block data (note this routine acts only on one block)
    real(kind=rk), intent(inout) :: u(:,:,:,:)
    !> spacing and origin of block
    real(kind=rk), intent(in) :: x0(1:3),dx(1:3)

    ! auxiliary variable for gauss pulse
    real(kind=rk)                           :: mux, muy, muz, x, z ,y, sigma
    ! loop variables
    integer(kind=ik)                        :: ix, iy, iz
    ! grid
    integer(kind=ik)                        :: Bs, g

!---------------------------------------------------------------------------------------------
! variables initialization
    Bs   = params%number_block_nodes
    g    = params%number_ghost_nodes


!---------------------------------------------------------------------------------------------
! main body

    ! place pulse in the center of the domain
    mux = 0.5_rk * params%Lx
    muy = 0.5_rk * params%Ly
    muz = 0.5_rk * params%Lz

    ! pulse width
    sigma = params%inicond_width * params%Lx * params%Ly

    if (params%threeD_case) then
      sigma = params%inicond_width*params%Lx
      ! 3D case
      ! create gauss pulse
      do ix = g+1,Bs+g
        do iy = g+1,Bs+g
          do iz = g+1,Bs+g
            ! compute x,y coordinates from spacing and origin
            x = dble(ix-(g+1)) * dx(1) + x0(1)
            y = dble(iy-(g+1)) * dx(2) + x0(2)
            z = dble(iz-(g+1)) * dx(3) + x0(3)
            ! shift to new gauss blob center
            ! call shift_x_y( x, y, params%Lx,params%Ly )
            ! set actual inicond gauss blob
            u(ix,iy,iz,1) = dexp( -( (x-mux)**2 + (y-muy)**2 +(z-muz)**2 ) / sigma )
          end do
        end do
      end do

    else

      ! 2D case
      ! create gauss pulse
      do ix = g+1,Bs+g
        do iy = g+1,Bs+g
          ! compute x,y coordinates from spacing and origin
          x = dble(ix-(g+1)) * dx(1) + x0(1)
          y = dble(iy-(g+1)) * dx(2) + x0(2)
          ! shift to new gauss blob center
          call shift_x_y( x, y, params%Lx,params%Ly )
          ! set actual inicond gauss blob
          u(ix,iy,1,1) = dexp( -( (x-mux)**2 + (y-muy)**2 ) / sigma )
        end do
      end do
  endif

end subroutine inicond_gauss_blob

! function to ensure periodicity:
! shift center of gauss blob to center of computational domain
! if then point(x,y) outside domain -> set coordinates to (periodic) interior point
subroutine shift_x_y( x, y, Lx, Ly )

    use module_params

    implicit none

    ! coordinates
    real(kind=rk), intent(inout)   :: x, y
    ! domain size
    real(kind=rk), intent(in)       :: Lx, Ly

    x = x
    y = y - 0.25_rk

    ! check boundary
    if ( y < 0.0_rk ) then
        y = Ly + y
    end if

    if ( x < 0.0_rk ) then
        x = Lx + x
    end if

    if ( y > Ly ) then
        y = Ly - y
    end if

    if ( x > Lx ) then
        x = Lx - x
    end if

end subroutine shift_x_y
