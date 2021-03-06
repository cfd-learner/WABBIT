!> \file
!> \callgraph
! ********************************************************************************************
! WABBIT
! ============================================================================================
!> \name read_field.f90
!> \version 0.5
!> \author engels, sm
!
!> \brief read data of a single datafield dF at iteration and time t
!
!>
!! input:
!!           - name of the file we want to read from
!!           - number of datafield
!!           - parameter array
!!           - number of active blocks (heavy)
!!
!! output:
!!           - heavy data array
!!
!!
!! = log ======================================================================================
!! \n
!! 22/09/17 - create
!
! ********************************************************************************************

subroutine read_field(fname, dF, params, hvy_block, hvy_n)

!---------------------------------------------------------------------------------------------
! modules

!---------------------------------------------------------------------------------------------
! variables

    implicit none

    !> file name
    character(len=*), intent(in)        :: fname
    !> datafield number
    integer(kind=ik), intent(in)        :: dF
    !> user defined parameter structure
    type (type_params), intent(in)      :: params
    !> heavy data array - block data
    real(kind=rk), intent(inout)        :: hvy_block(:, :, :, :, :)
    !> number of heavy and light active blocks
    integer(kind=ik), intent(in)        :: hvy_n

    ! block data buffer, need for compact data storage
    real(kind=rk), allocatable          :: myblockbuffer(:,:,:,:)

    ! file id integer
    integer(hid_t)                      :: file_id


    ! process rank
    integer(kind=ik)                    :: rank
    ! grid parameter
    integer(kind=ik)                    :: Bs, g

    ! offset variables
    integer(kind=ik), dimension(4)      :: ubounds3D, lbounds3D
    integer(kind=ik), dimension(3)      :: ubounds2D, lbounds2D

    ! procs per rank array
    integer, dimension(:), allocatable  :: actual_blocks_per_proc

!---------------------------------------------------------------------------------------------
! variables initialization

    ! set MPI parameters
    rank = params%rank

    ! grid parameter
    Bs   = params%number_block_nodes
    g    = params%number_ghost_nodes

    allocate(actual_blocks_per_proc( 0:params%number_procs-1 ))
    allocate(myblockbuffer( 1:Bs, 1:Bs, 1:Bs, 1:hvy_n ))
!---------------------------------------------------------------------------------------------
! main body

    call check_file_exists(fname)
    ! open the file
    call open_file_hdf5( trim(adjustl(fname)), file_id, .false.)

    call blocks_per_mpirank( params, actual_blocks_per_proc, hvy_n )

    if ( params%threeD_case ) then

        ! tell the hdf5 wrapper what part of the global [Bs x Bs x Bs x hvy_n]
        ! array we want to hold, so that all CPU can read from the same file simultaneously
        ! (note zero-based offset):
        lbounds3D = (/0,0,0,sum(actual_blocks_per_proc(0:rank-1))/)
        ubounds3D = (/Bs-1,Bs-1,Bs-1,lbounds3D(4)+hvy_n-1/)

    else

        ! tell the hdf5 wrapper what part of the global [Bs x Bs x 1 x hvy_n]
        ! array we want to hold, so that all CPU can read from the same file simultaneously
        ! (note zero-based offset):
        lbounds2D = (/0,0,sum(actual_blocks_per_proc(0:rank-1))/)
        ubounds2D = (/Bs-1,Bs-1,lbounds2D(3)+hvy_n-1/)

    endif

    ! print a message
    if (rank==0) then
        write(*,'(80("_"))')
        write(*,'("READING: Reading datafield ",i2," from file ",A)') dF,&
        trim(adjustl(fname))
    end if

    ! actual reading of file
    if ( params%threeD_case ) then
        ! 3D data case
        call read_dset_mpi_hdf5_4D(file_id, "blocks", lbounds3D, ubounds3D, myblockbuffer)

    else
        ! 2D data case
        call read_dset_mpi_hdf5_3D(file_id, "blocks", lbounds2D, ubounds2D, myblockbuffer(:,:,1,:))
    end if

    ! close file and HDF5 library
    call close_file_hdf5(file_id)

    ! copy data to heavy block array (without ghost nodes)
    if (params%threeD_case) then
        hvy_block(g+1:Bs+g,g+1:Bs+g,g+1:Bs+g,dF,1:hvy_n) = myblockbuffer(:,:,:,1:hvy_n)
    else
        hvy_block(g+1:Bs+g,g+1:Bs+g,1,dF,1:hvy_n) = myblockbuffer(:,:,1,1:hvy_n)
    end if

    deallocate(myblockbuffer)
end subroutine read_field
