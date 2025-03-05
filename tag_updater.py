import argparse
import pandas as pd
import boto3
import time

def get_ec2_client(profile, region):
    """Create a boto3 EC2 client."""
    session = boto3.Session(profile_name=profile, region_name=region)
    return session.client('ec2')

def get_volume_info(ec2_client, volume_id):
    """Retrieve volume details using boto3 with retry logic."""
    for _ in range(3):
        try:
            response = ec2_client.describe_volumes(VolumeIds=[volume_id])
            return response['Volumes'][0] if response['Volumes'] else None
        except Exception as e:
            print(f"Error retrieving volume {volume_id}: {e}")
            time.sleep(2)
    return None

def get_instance_info(ec2_client, instance_id):
    """Retrieve instance details using boto3 with retry logic."""
    for _ in range(3):
        try:
            response = ec2_client.describe_instances(InstanceIds=[instance_id])
            return response['Reservations'][0]['Instances'][0] if response['Reservations'] else None
        except Exception as e:
            print(f"Error retrieving instance {instance_id}: {e}")
            time.sleep(2)
    return None

def update_volume_tag(ec2_client, volume_id, tag_key, tag_value):
    """Update EBS volume tag."""
    try:
        ec2_client.create_tags(Resources=[volume_id], Tags=[{'Key': tag_key, 'Value': tag_value}])
    except Exception as e:
        print(f"Error updating tag on volume {volume_id}: {e}")

def process_excel(file_path, sheet_name, profile, region):
    """Process the Excel file to check and update EBS volume tags."""
    ec2_client = get_ec2_client(profile, region)
    df = pd.read_excel(file_path, sheet_name=sheet_name)
    report_data = []
    
    for _, row in df.iterrows():
        volume_id = str(row['Instance ID']).strip()
        volume_info = get_volume_info(ec2_client, volume_id)
        
        if not volume_info:
            report_data.append([volume_id, None, None, None, None, None, False, False, None, None, None, True])
            continue
        
        attachments = volume_info.get('Attachments', [])
        if not attachments:
            report_data.append([volume_id, None, None, None, None, None, False, False, None, None, None, True])
            continue
        
        instance_id = attachments[0]['InstanceId']
        instance_info = get_instance_info(ec2_client, instance_id)
        
        if not instance_info:
            report_data.append([volume_id, instance_id, None, None, None, None, False, False, None, None, None, False])
            continue
        
        instance_tags = {t['Key']: t['Value'] for t in instance_info.get('Tags', [])}
        volume_tags = {t['Key']: t['Value'] for t in volume_info.get('Tags', [])}
        
        instance_tag_value = instance_tags.get('pcm-project_number')
        volume_tag_value = volume_tags.get('pcm-project_number')
        
        instance_empty_tag = instance_tag_value == "empty"
        instance_missing_tag = instance_tag_value is None
        
        if instance_missing_tag:
            report_data.append([volume_id, instance_id, 'pcm-project_number', volume_tag_value, 'pcm-project_number', None, False, False, None, True, None, False])
            continue
        
        if volume_tag_value == 'empty':
            update_volume_tag(ec2_client, volume_id, 'pcm-project_number', instance_tag_value)
            volume_tag_value = instance_tag_value
        
        match = volume_tag_value == instance_tag_value
        non_match = not match and volume_tag_value is not None
        
        report_data.append([
            volume_id, instance_id, 'pcm-project_number', volume_tag_value, 'pcm-project_number', instance_tag_value, 
            match, non_match, volume_tag_value if non_match else None, instance_missing_tag, instance_empty_tag, False
        ])
    
    columns = ['EBS Volume ID', 'EC2 Instance ID', 'Tag Key for EBS', 'Tag Value for EBS',
               'Tag Key for EC2', 'Tag Value for EC2', 'Matches', 'Non-Match',
               'Non-Match Tag Value for EBS', 'Instance Missing Tag', 'Instance Empty Tag', 'EBS No Association']
    report_df = pd.DataFrame(report_data, columns=columns)
    output_file = "aws_tag_report.xlsx"
    report_df.to_excel(output_file, index=False)
    print(f"Report saved as {output_file}")

def main():
    parser = argparse.ArgumentParser(description='AWS EBS Tag Updater')
    parser.add_argument('--file', type=str, required=True, help='Excel file path')
    parser.add_argument('--sheet', type=str, default='Sheet1', help='Sheet name or index')
    parser.add_argument('--profile', type=str, required=True, help='AWS CLI profile')
    parser.add_argument('--region', type=str, help='AWS region (optional)')
    args = parser.parse_args()
    
    process_excel(args.file, args.sheet, args.profile, args.region)

if __name__ == "__main__":
    main()
