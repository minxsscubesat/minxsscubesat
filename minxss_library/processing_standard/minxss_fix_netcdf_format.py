import netCDF4 as nc
import os


def process_netcdf_file(src_file, instrument_name):
    # Normalize instrument names
    original_instrument_name = instrument_name.lower()
    if original_instrument_name in ['xp_dark', 'xp']:
        instrument_name = 'xp'
    elif original_instrument_name in ['x123_dark', 'x123']:
        instrument_name = 'x123'
    else:
        raise ValueError(f"Unknown instrument name: {original_instrument_name}")

    # Open the original NetCDF file in read mode
    src_dataset = nc.Dataset(src_file, 'r')

    # Create a new NetCDF file in the same directory
    src_dir = os.path.dirname(src_file)
    src_filename = os.path.basename(src_file)
    
    # Insert instrument name into filename only for fm3 (DAXSS)
    if 'daxss' in src_filename.lower() and '_solarSXR_' in src_filename:
        # Split at 'solarSXR_' and keep everything before it
        prefix = src_filename.split('_solarSXR_')[0]
        # Get everything after 'solarSXR_'
        suffix = src_filename.split('_solarSXR_')[1]
        
        # Construct new filename
        dst_filename = f"{prefix}_solarSXR_{instrument_name}_{suffix}"
        dst_file = os.path.join(src_dir, dst_filename)
    else:
        dst_file = os.path.join(src_dir, src_filename)
    
    dst_dataset = nc.Dataset(dst_file, 'w', format='NETCDF4')

    # Define the new dimensions
    time_dim = 'TIME'

    # Create the 'time' dimension (unlimited)
    dst_dataset.createDimension(time_dim, None)  # 'time' is unlimited

    # Check instrument and define relevant dimensions
    if instrument_name == 'x123':
        energy_dim = 'energy'
        dst_dataset.createDimension(energy_dim, src_dataset.dimensions['dim1_ENERGY'].size)
        dimensions_to_check = ['IRRADIANCE', 'SPECTRUM', 'ENERGY', 'VALID_FLAG']
    elif instrument_name == 'xp':
        dimensions_to_check = []  # XP doesn't have energy or the other specific dimensions

    # Copy global attributes
    for attr in src_dataset.ncattrs():
        dst_dataset.setncattr(attr, src_dataset.getncattr(attr))

    # Create and populate the 'time' variable
    time_data = src_dataset.variables['TIME_TAI'][:]
    time_var = dst_dataset.createVariable(time_dim, time_data.dtype, (time_dim,))
    time_var[:] = time_data

    # Copy other variables, reassigning dimensions as needed
    for name, variable in src_dataset.variables.items():
        # Skip the TIME_TAI since we've already processed it
        if name == 'TIME_TAI':
            continue

        # Adjust dimensions based on the instrument
        if any(dim_name in name for dim_name in dimensions_to_check):
            new_dimensions = (time_dim, energy_dim)
        elif 'structure_elements' in variable.dimensions:
            # Replace 'structure_elements' with 'time'
            new_dimensions = tuple(time_dim if dim == 'structure_elements' else dim for dim in variable.dimensions)
        else:
            new_dimensions = variable.dimensions

        # Create the variable in the new dataset
        dst_var = dst_dataset.createVariable(name, variable.datatype, new_dimensions)
        
        # Copy variable attributes
        dst_var.setncatts({k: variable.getncattr(k) for k in variable.ncattrs()})
        
        # Copy data
        dst_var[:] = variable[:]

    # Convert former dimensions (except 'energy') to variables with 'time' dimension
    for dim_name in src_dataset.dimensions:
        if instrument_name == 'x123' and dim_name == 'dim1_ENERGY':
            continue  # Skip if it's the energy dimension for x123
        if dim_name != time_dim:
            # Check if the dimension has a corresponding variable
            if dim_name in src_dataset.variables:
                # Create a new variable with the 'time' dimension
                data = src_dataset.variables[dim_name][:]
                dst_var = dst_dataset.createVariable(dim_name, data.dtype, (time_dim,))
                dst_var[:] = data
            else:
                print(f"Skipping dimension '{dim_name}' as it does not have a corresponding variable.")

    # Add metadata for the time dimension variable
    time_var.setncatts({
        'UNITS': 'seconds since 1958-01-01T00:00:00 TAI',
        'LONG_NAME': 'Time (TAI)',
        'STANDARD_NAME': 'time',
        'CALENDAR': 'gregorian'
    })


    # Close both datasets
    src_dataset.close()
    dst_dataset.close()

    print(f"Fixed NetCDF file saved as {dst_file}")

def main():
    fm = '3'  # can be '1', '2', or '3'
    version = '3.0.0'
    
    # Get user's home directory
    home_dir = os.path.expanduser('~')
    base_path = os.path.join(home_dir, 'Dropbox/minxss_dropbox/data')

    if fm == '3':
        instruments = ['x123', 'x123_dark']
        mission_name = 'daxss'
        start_date = '2022-02-14'
    else:
        instruments = ['x123', 'x123_dark', 'xp', 'xp_dark']
        
        if fm == '1': 
            mission_name = 'minxss'
            start_date = '2016-05-16'
        elif fm == '2': 
            mission_name = 'minxss'
            start_date = '2018-12-03'

    levels = ['1', '2', '3']
    for level in levels:
        print(f"\nProcessing level {level} data...")
        for instrument in instruments:
            print(f"Processing instrument: {instrument}")
            
            if mission_name == 'minxss':
                if level == '1':
                    src_file = os.path.join(base_path, f'fm{fm}/level1/{mission_name}{fm}_solarSXR_{instrument}_level1_{start_date}-mission_v{version}.nc')
                elif level == '2':
                    src_file_minute = os.path.join(base_path, f'fm{fm}/level2/{mission_name}{fm}_solarSXR_level2_1minute_average_{start_date}-mission_v{version}.nc')
                    src_file_hour = os.path.join(base_path, f'fm{fm}/level2/{mission_name}{fm}_solarSXR_level2_1hour_average_{start_date}-mission_v{version}.nc')
                elif level == '3': 
                    src_file = os.path.join(base_path, f'fm{fm}/level3/{mission_name}{fm}_solarSXR_level3_1day_average_{start_date}-mission_v{version}.nc')
            else: 
                if level == '1':
                    src_file = os.path.join(base_path, f'fm{fm}/level1/{mission_name}_solarSXR_level1_{start_date}-mission_v{version}.nc')
                elif level == '2':
                    src_file_minute = os.path.join(base_path, f'fm{fm}/level2/{mission_name}_solarSXR_level2_1minute_average_{start_date}-mission_v{version}.nc')
                    src_file_hour = os.path.join(base_path, f'fm{fm}/level2/{mission_name}_solarSXR_level2_1hour_average_{start_date}-mission_v{version}.nc')
                elif level == '3': 
                    src_file = os.path.join(base_path, f'fm{fm}/level3/{mission_name}_solarSXR_level3_1day_average_{start_date}-mission_v{version}.nc')

            # Skip processing x123_dark for level 2 and 3 data for MinXSS-1 and MinXSS-2
            if fm in ['1', '2'] and level in ['2', '3'] and instrument != 'x123':
                print(f"Skipping {instrument} for level {level} data (not applicable for MinXSS-{fm})")
                continue

            if level != '2': 
                process_netcdf_file(src_file, instrument)
            else: 
                process_netcdf_file(src_file_minute, instrument)
                process_netcdf_file(src_file_hour, instrument)

if __name__ == "__main__":
    main()
