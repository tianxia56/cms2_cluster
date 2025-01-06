import os

# Define the directory containing the .sh files
directory = '.'

# Loop through all files in the directory
for filename in os.listdir(directory):
    # Check if the file is a .sh file
    if filename.endswith('.sh'):
        # Read the content of the file
        with open(filename, 'r') as file:
            content = file.readlines()
        
        # Replace the specific line if it exists
        new_content = []
        for line in content:
            if line.strip() == '#SBATCH --time=2:00:00':
                new_content.append('#SBATCH --time=2-00:00:00\n')
            else:
                new_content.append(line)
        
        # Write the modified content back to the file
        with open(filename, 'w') as file:
            file.writelines(new_content)

print("All .sh files have been processed.")

#SBATCH --partition=ycga
#SBATCH --partition=week