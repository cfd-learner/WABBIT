!> \file
!> \callgraph
! ********************************************************************************************
! WABBIT
! ============================================================================================
!> \name module_params.f90
!> \version 0.4
!> \author msr
!
!> \brief params data structure, define all constant parameters for global use
!
!> \todo module actually only works for specific RHS, split between RHS parameters and program
!!       parameters in future versions
!
!> \details
!> = log ======================================================================================
!! \n
!! 04/11/16 - switch to v0.4, merge old block_params structure with new structure
! ********************************************************************************************

module module_params

!---------------------------------------------------------------------------------------------
! modules
    use mpi
    ! use physics module
    use module_convection_diffusion
    use module_navier_stokes
    use module_acm
    ! ini file parser module
    use module_ini_files_parser_mpi

!---------------------------------------------------------------------------------------------
! variables

    implicit none

    ! global user defined data structure for time independent variables
    type type_params

        ! maximal time for main time loop
        real(kind=rk)                                :: time_max
        ! CFL criteria for time step calculation
        real(kind=rk)                                :: CFL
        ! dt
        real(kind=rk)                                :: dt
        ! time step calculator
        character(len=80)                            :: time_step_calc
        ! data writing frequency
        integer(kind=ik)                             :: write_freq
        ! data writing frequency
        character(len=80)                            :: write_method
        ! data writing frequency
        real(kind=rk)                                :: write_time
        ! data next write time, store here the next time for output data
        real(kind=rk)                                :: next_write_time

        ! butcher tableau containing coefficients for Runge-Kutta method
        real(kind=rk), dimension(:,:), allocatable   :: butcher_tableau

        ! threshold for wavelet indicator
        real(kind=rk)                                :: eps
        ! minimal level for blocks in data tree
        integer(kind=ik)                             :: min_treelevel
        ! maximal level for blocks in data tree
        integer(kind=ik)                             :: max_treelevel

        ! order of refinement predictor
        character(len=80)                            :: order_predictor
        ! order of spatial discretization
        character(len=80)                            :: order_discretization
        ! boundary condition
        character(len=80)                            :: boundary_cond
        ! initial condition
        character(len=80)                            :: initial_cond
        ! files we want to read for inital cond.
        character(len=80), dimension(:), allocatable :: input_files
        ! width of the initial condition (e.g. Gauss blob)
        real(kind=rk)                                :: inicond_width

        ! penalization?
        logical                                      :: penalization
        ! penalization factor
        real(kind=rk)                                :: eps_penal
        ! smooth mask for penalization term
        logical                                      :: smooth_mask
        ! geometry for VPM
        character(len=80)                            :: geometry

        ! grid parameter
        integer(kind=ik)                             :: number_domain_nodes
        integer(kind=ik)                             :: number_block_nodes
        integer(kind=ik)                             :: number_ghost_nodes

        ! switch for mesh adaption
        logical                                      :: adapt_mesh

        ! number of allocated heavy data fields per process
        integer(kind=ik)                             :: number_blocks
        ! number of allocated data fields in heavy data array, number of fields in heavy work data (depend from time step scheme, ...)
        integer(kind=ik)                             :: number_data_fields
        integer(kind=ik)                             :: number_fields

        ! block distribution for load balancing (also used for start distribution)
        character(len=80)                            :: block_distribution

        ! debug flag
        logical                                      :: debug

        ! use non-uniform mesh correction
        logical                                      :: non_uniform_mesh_correction

        ! -------------------------------------------------------------------------------------
        ! physics
        ! -------------------------------------------------------------------------------------
        ! physics type
        character(len=80)                            :: physics_type

        ! domain length
        real(kind=rk)                                :: Lx, Ly, Lz

        ! physics substructure
        type(type_params_convection_diffusion_physics) :: physics
        type(type_params_physics_navier_stokes)     :: physics_ns
        type(type_params_physics_acm)               :: physics_acm

        ! use third dimension
        logical                                     :: threeD_case

        ! -------------------------------------------------------------------------------------
        ! MPI
        ! -------------------------------------------------------------------------------------
        ! data exchange method
        character(len=80)                           :: mpi_data_exchange

        ! process rank
        integer(kind=ik)                            :: rank
        ! number of processes
        integer(kind=ik)                            :: number_procs

        ! -------------------------------------------------------------------------------------
        ! unit test
        ! -------------------------------------------------------------------------------------
        ! unit test params struct
        logical                                     :: unit_test
        ! unit test ghost nodes synchronization flag
        logical                                     :: test_ghost_nodes_synch
        ! unit test time_stepper convergence flag
        logical                                     :: test_time_stepper
        ! unit test spatial convergence flag
        logical                                     :: test_spatial
        ! unit test wavelet compression
        logical                                     :: test_wavelet_comp
        ! unit test treecode flag
        logical                                     :: test_treecode

        ! -------------------------------------------------------------------------------------
        ! filter
        ! -------------------------------------------------------------------------------------
        ! type
        character(len=80)                           :: filter_type
        ! frequency
        integer(kind=ik)                            :: filter_freq
        ! bogey shock detector threshold
        real(kind=rk)                               :: r_th

    end type type_params

!---------------------------------------------------------------------------------------------
! variables initialization

!---------------------------------------------------------------------------------------------
! main body
contains

    ! this file reads the ini file and distributes all the parameters to the
    ! various structs holding them
    include "ini_file_to_params.f90"

! --------------------------------------------------------------------
! INTEGER FUNCTION  FindMinimum():
!    This function returns the location of the minimum in the section
! between Start and End.
! --------------------------------------------------------------------

!   INTEGER FUNCTION  FindMinimum(x, Start, End)
!      IMPLICIT  NONE
!      INTEGER, DIMENSION(1:), INTENT(IN) :: x
!      INTEGER, INTENT(IN)                :: Start, End
!      INTEGER                            :: Minimum
!      INTEGER                            :: Location
!      INTEGER                            :: i
!
!      Minimum  = x(Start)      ! assume the first is the min
!      Location = Start         ! record its position
!      DO i = Start+1, End      ! start with next elements
!         IF (x(i) < Minimum) THEN  !   if x(i) less than the min?
!            Minimum  = x(i)        !      Yes, a new minimum found
!            Location = i                !      record its position
!         END IF
!      END DO
!      FindMinimum = Location           ! return the position
!   END FUNCTION  FindMinimum
!
!! --------------------------------------------------------------------
!! SUBROUTINE  Swap():
!!    This subroutine swaps the values of its two formal arguments.
!! --------------------------------------------------------------------
!
!   SUBROUTINE  Swap(a, b)
!      IMPLICIT  NONE
!      INTEGER, INTENT(INOUT) :: a, b
!      INTEGER                :: Temp
!
!      Temp = a
!      a    = b
!      b    = Temp
!   END SUBROUTINE  Swap
!
!! --------------------------------------------------------------------
!! SUBROUTINE  Sort():
!!    This subroutine receives an array x() and sorts it into ascending
!! order.
!! --------------------------------------------------------------------
!
!   SUBROUTINE  Sort(x)
!      IMPLICIT  NONE
!      INTEGER, DIMENSION(:,:), INTENT(INOUT) :: x
!      INTEGER                               :: sze, ndata
!      INTEGER                               :: i
!      INTEGER                               :: Location
!
!      sze = size(x,1)
!      ndata = size(x,2)
!
!       ! SORT KEY IS SECOND ENTRY!!!!!!!!!!!!!!!
!
!      DO i = 1, sze-1          ! except for the last
!         Location = FindMinimum(x(:,2), i, sze)    ! find min from this to last
!         CALL  Swap(x(i,1), x(Location,1)) ! swap this and the minimum
!         CALL  Swap(x(i,2), x(Location,2)) ! swap this and the minimum
!      END DO
!   END SUBROUTINE  Sort
!
!subroutine barrier
!  use mpi
!  implicit none
!  integer :: ierr
!
!  call MPI_BARRIER(MPI_COMM_WORLD, ierr)
!end subroutine

end module module_params
