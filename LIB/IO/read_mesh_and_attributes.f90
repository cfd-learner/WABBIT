!> \file
!> \callgraph
! ********************************************************************************************
! WABBIT
! ============================================================================================
!> \name read_mesh_and_attributes.f90
!> \version 0.5
!> \author sm
!
!> \brief read mesh properties and attributes (iteration and time t) of a field saved in a hdf5-file
!
!>
!! input:
!!           - parameter array
!!           - name of the file we want to read from
!!
!! output:
!!           - light block array
!!           - time and iteration
!!           - number of active blocks (light and heavy)
!!
!!
!! = log ======================================================================================
!! \n
!! 29/09/17 - create
!
! ********************************************************************************************

subroutine read_mesh_and_attributes(fname, params, lgt_n, hvy_n, lgt_block, time, iteration)

!---------------------------------------------------------------------------------------------
! modules

!---------------------------------------------------------------------------------------------
! variables

    implicit none

    !> file name
    character(len=*), intent(in)                  :: fname
    !> user defined parameter structure
    type (type_params), intent(in)                :: params
    !> number of active blocks (heavy and light data)
    integer(kind=ik), intent(inout)               :: hvy_n, lgt_n
    !> light data array
    integer(kind=ik), intent(inout)               :: lgt_block(:,:)
    !> time (to be read from file)
    real(kind=rk), intent(inout)                  :: time
    !> iteration (to be read from file)
    integer(kind=ik), intent(inout)               :: iteration

    ! file id integer
    integer(hid_t)                                :: file_id
    ! process rank, number of procs
    integer(kind=ik)                              :: rank, number_procs
    ! grid parameter
    integer(kind=ik)                              :: Bs, g
    ! offset variables
    integer(kind=ik), dimension(2)                :: ubounds, lbounds
    ! treecode array
    integer(kind=ik), dimension(:,:), allocatable :: block_treecode
    integer(kind=ik), dimension(:,:), allocatable :: my_lgt_block
    integer(kind=ik)                              :: blocks_per_rank_list(0:params%number_procs-1) 
    ! loop variables
    integer(kind=rk)                              :: lgt_id, k
    ! error variable
    integer(kind=ik)                              :: ierr
    integer(kind=ik), dimension(1)                :: iiteration, number_blocks
    real(kind=rk), dimension(1)                   :: ttime
    integer(kind=ik)                              :: treecode_size
    real(kind=rk), dimension(3)                   :: domain
!---------------------------------------------------------------------------------------------
! variables initialization

    ! set MPI parameters
    rank         = params%rank
    number_procs = params%number_procs
    ! grid parameter
    Bs   = params%number_block_nodes
    g    = params%number_ghost_nodes
    
    lgt_id = 0
!---------------------------------------------------------------------------------------------
! main body

    call check_file_exists(fname)
    ! open the file
    call open_file_hdf5( trim(adjustl(fname)), file_id, .false.)

    call read_attribute(file_id, "blocks", "domain-size", domain)
    if (.not. (params%threeD_case)) domain(3) = params%Lz
    call read_attribute(file_id, "blocks", "time", ttime)
    call read_attribute(file_id, "blocks", "iteration", iiteration)
    call read_attribute(file_id, "blocks", "total_number_blocks", number_blocks)

    time      = ttime(1)
    lgt_n     = number_blocks(1)
    iteration = iiteration(1)

    ! print time, iteration and domain on screen
    if (rank==0) then
        write(*,'(80("_"))')
        write(*,'("READING: Reading from file ",A)') trim(adjustl(fname))
        write(*,'("time=",g12.4," iteration=", i5)') time, iteration
        write(*,'("Lx=",g12.4," Ly=",g12.4," Lz=",g12.4)') domain

        ! if the domain size doesn't match, proceed, but yell.
        if ((abs(params%Lx-domain(1))>1e-12_rk).or.(abs(params%Ly-domain(2))>1e-12_rk) &
            .or.(abs(params%Lz-domain(3))>1e-12_rk)) then
            write (*,'(A)') " WARNING! Domain size mismatch."
            write (*,'("in memory:   Lx=",es12.4,"Ly=",es12.4,"Lz=",es12.4)') params%Lx, params%Ly, params%Lz
            write (*,'("but in file: Lx=",es12.4,"Ly=",es12.4,"Lz=",es12.4)') domain
            write (*,'(A)') "proceed, with fingers crossed."
        end if
    end if

    if ( (rank == 0) ) then
        write(*,'(80("_"))')
        write(*,'(A)') "READING: initializing grid from file..."
        write(*,'( "Nblocks=",i6," (on all cpus)")') lgt_n
        ! check if there is already some data on the grid
        if ( maxval(lgt_block(:,1))>=0 ) then
            write(*,'(A)') "ERROR: READ_MESH is called with NON_EMPTY DATA!!!!!"
        end if
    end if

    ! Nblocks per CPU
    ! this list contains (on each mpirank) the number of blocks for each mpirank. note
    ! zero indexing as required by MPI

    ! set list to the average value
    blocks_per_rank_list = lgt_n / number_procs

    ! as this does not necessarily work out, distribute remaining blocks on the first CPUs
    if (mod(lgt_n, number_procs) > 0) then
        blocks_per_rank_list(0:mod(lgt_n, number_procs)-1) = blocks_per_rank_list(0:mod(lgt_n, number_procs)-1) + 1
    end if
    ! some error control -> did we loose blocks? should never happen.
    if ( sum(blocks_per_rank_list) /= lgt_n) then
        call error_msg("ERROR: while reading from file, we seem to have gained/lost some blocks during distribution...")
    end if

    ! number of active blocks on my process
    ! WHAT HAPPENS IF HVY_N = 0 ?????????
    hvy_n = blocks_per_rank_list(rank)

    allocate(block_treecode(1:params%max_treelevel, 1:hvy_n))
    allocate (my_lgt_block(size(lgt_block,1), size(lgt_block,2)))
    my_lgt_block = -1

    ! tell the hdf5 wrapper what part of the global [ n_active x max_treelevel + 2]
    ! array we want to hold, so that all CPU can read from the same file simultaneously
    ! (note zero-based offset):
    lbounds = (/0, sum(blocks_per_rank_list(0:rank-1))/)
    ubounds = (/params%max_treelevel-1, lbounds(2) + hvy_n - 1/)

    call read_dset_mpi_hdf5_2D(file_id, "block_treecode", lbounds, ubounds, block_treecode)

    ! close file and HDF5 library
    call close_file_hdf5(file_id)
     do k=1, hvy_n
        call hvy_id_to_lgt_id( lgt_id, k, rank, params%number_blocks )
        ! copy treecode
        my_lgt_block(lgt_id,1:params%max_treelevel) = block_treecode(:,k)
        ! set mesh level
        my_lgt_block(lgt_id, params%max_treelevel+1) = treecode_size(block_treecode(:,k), params%max_treelevel)
        ! set refinement status 
        my_lgt_block(lgt_id, params%max_treelevel+2) = 0
    end do

    ! synchronize light data. This is necessary as all CPUs above created their blocks locally.
    ! As they all pass the same do loops, the counter array blocks_per_rank_list does not have to
    ! be synced. However, the light data has to.
    lgt_block = 0
    call MPI_Allreduce(my_lgt_block, lgt_block, size(lgt_block,1)*size(lgt_block,2), MPI_INTEGER4, MPI_MAX, MPI_COMM_WORLD, ierr)

    deallocate(my_lgt_block)
    deallocate(block_treecode)

end subroutine read_mesh_and_attributes
