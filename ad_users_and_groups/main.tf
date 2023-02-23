locals {
    csv_data = <<-CSV
    name,bucket
    AWS-EKS-Privileged-ReadOnly,developer
    AWS-EKS-Privileged-Administrator-Dev,developer
    AWS-EKS-Privileged-Administrator-Prod,infrastructure
    test, developer
  CSV
    
    managers_data = <<-CSV
    upn,team,organization,bucket
    jjayaraman,esg,zuora-zcloud,infrastructure
    vvenkataraman,techops,zuora-zcloud,infrastructure
    ssrinivasan,esg-india,zuora-zcloud,infrastructure
    rpolishetty,nova,zuora-zcloud,developer
    zlouis,zflakes,zuora-zcloud,developer
  CSV
    
    existing_group_data = <<-CSV
    name,id,bucket
    aws-na-dev-01-app-devOpsEngineer-group,388554d9-7e2e-4a52-94a7-5fe0def470a2,developer
    aws-na-prod-01-viewer-readOnly-group,a94dfcda-d886-40f1-80b1-bbcec3d8e7f8,developer
    aws-na-dev-01-foundation-fullAdmin-group,dc4e6b71-957e-4af0-9d5b-4394e292c9a2,infrastructure
    aws-na-prod-01-foundation-fullAdmin-group,9a973982-0b50-4cf4-8343-1e7f04aeb0b7,infrastructure
    aws-na-stg-01-foundation-fullAdmin-group,0ddece18-3279-456a-bd01-4540793699db,infrastructure
    aws-na-sbx-01-foundation-fullAdmin-group,7152762a-c4a0-47b0-b0a8-162e287be8fb,infrastructure
    aws-na-stg-01-app-devOpsEngineer-group,1d1728d8-6c94-4428-8e60-2eebabf67b49,developer
    aws-na-sbx-01-viewer-readOnly-group,7c598666-9ec3-44c0-b336-5788a0627c3a,developer
    aws-na-admin-foundation-fullAdmin-group,866bfb84-5a4d-4f76-979a-a0b3e93ad551,infrastructure
  CSV
    
    users_data = <<-CSV
    upn,manager
    abhi,jjayaraman
    siverma,jjayaraman
    schaudhari,jjayaraman
    stindell,jjayaraman
    amoguilevski,jjayaraman
    danguyen,jjayaraman
    pnikzad,jjayaraman
    ozavorin,jjayaraman
    hkalashnyk,jjayaraman
    vfateyev,jjayaraman
    akotsenko,jjayaraman
    amalko,jjayaraman
    scherednychenko,jjayaraman
    ishestopalov,jjayaraman
    oarabadzhy,jjayaraman
    ykrestyansky,jjayaraman
    oshyrokov,jjayaraman
    mzmushko,jjayaraman
    ssrinivasan,jjayaraman
    okimenker,jjayaraman
    eosman,jjayaraman
    balmeidamaldonado,jjayaraman
    szumbado,jjayaraman
    darce,jjayaraman
    jiangtao.liu,jjayaraman
    chen.qin,vvenkataraman
    justin.smith,vvenkataraman
    smurillo,vvenkataraman
    rbarabas,vvenkataraman
    kmayeux,vvenkataraman
    nbidhuri,vvenkataraman
    agore,vvenkataraman
    kgovindaraj,vvenkataraman
    skanakaraju,vvenkataraman
    ssubbarayalu,vvenkataraman
    dahuja,vvenkataraman
    ngarimaldi.zteam,vvenkataraman
    tcole.zteam,vvenkataraman
    pwu,vvenkataraman
    egordin,vvenkataraman
    rananthula,vvenkataraman
    vpattel,vvenkataraman
    dalee,vvenkataraman
    gparwar,vvenkataraman
    lprasanna,vvenkataraman
    dmunk,vvenkataraman
    kduraikannu,vvenkataraman
    arkumar,vvenkataraman
    jjayaraman,vvenkataraman
    lborbon,vvenkataraman
    lisheng.liu,vvenkataraman
    scott.blashek,vvenkataraman
    joreddy,ssrinivasan
    sansingh,ssrinivasan
    ritsingh,ssrinivasan
    dkatre,ssrinivasan
    nroselin,ssrinivasan
    rpolishetty,rpolishetty
    sbalachandra,rpolishetty
    vkannan,rpolishetty
    mhazarika,rpolishetty
    cponmudi,rpolishetty
    dramamoorthy,rpolishetty
    smotapothula,rpolishetty
    gbalakrishnan,rpolishetty
    hkunkasubramanian,rpolishetty
    achaudhary,rpolishetty
    mtripathy,rpolishetty
    bshanmugasundaram,rpolishetty
    pbaskar,rpolishetty
    dluu,zlouis
  CSV

    groups = csvdecode(local.csv_data)
    users = csvdecode(local.users_data)
    existing_groups = csvdecode(local.existing_group_data)
    managers = csvdecode(local.managers_data)
    #users = csvdecode(file(var.users_file_path))
    #groups = csvdecode(file(var.groups_file_path))
    #groups = csvdecode("name,bucket\nAWS-EKS-Privileged-ReadOnly,developer\nAWS-EKS-Privileged-Administrator-Dev,developer\nAWS-EKS-Privileged-Administrator-Prod,infrastructure\nTest,developer")
    #groups = csvdecode(file("/runner/_work/terraspace-infra/terraspace-infra/csvs/AzureCSVs/groups.csv"))
    #existing_groups = csvdecode(file(var.existing_groups_file_path))
    #managers = csvdecode(file(var.managers_file_path))

    // maps each individual bucket to all of the AD groups that fall under
    bucket_to_groups = flatten([
        for row in local.groups : [
            {
                bucket = row.bucket
                group = row.name
            }
        ]
    ])

    bucket_to_groups_map = {
        for pu in local.bucket_to_groups :
            pu.bucket => pu.group... // the elllipses means accept duplicate keys
    }


    // get object ids and group display name from the resource used to create the groups
    group_id_list = [
        for tn, t in azuread_group.csv_group : {
            id = t.id
            name = t.display_name
        }
    ]

    // map of group display name => group object id
     group_to_id_map = {
        for group in local.group_id_list :
            group.name => group.id
    }

    // maps each individual bucket to all of the AD groups that fall under
    bucket_to_existing_groups = flatten([
        for row in local.existing_groups : [
            {
                bucket = row.bucket
                group = row.name
            }
        ]
    ])

    bucket_to_existing_groups_map = {
        for pu in local.bucket_to_existing_groups :
            pu.bucket => pu.group... // the elllipses means accept duplicate keys
    }

    existing_group_to_id_map = {
        for group in local.existing_groups :
            group.name => group.id
    }

    // maps managers to the bucket users under them are added
    manager_to_bucket_map = {
        for manager in local.managers :
            manager.upn => manager.bucket
    }

    // grabs existing users object id
    existing_user_id_list = [
        for tn, t in data.azuread_user.existing_users : {
            id = t.id
            display_name = t.display_name
            user_principal_name = t.user_principal_name
        }
    ]

    existing_user_id_map = {
        for user in local.existing_user_id_list :
            trimsuffix(user.user_principal_name, var.azure_domain) => user.id
    }

    // create string pairs of user_ids -> groups_ids in which they are to be added
    user_group_id_pairs = flatten ([
        for user in local.users : [
            for group in local.bucket_to_groups_map[local.manager_to_bucket_map[user.manager]] :
                format("%s %s", local.existing_user_id_map[user.upn], local.group_to_id_map[group])
        ]
    ])
    
    // create string pairs of user_ids -> groups_ids in which they are to be added
    user_existing_group_id_pairs = flatten ([
        for user in local.users : [
            for group in local.bucket_to_existing_groups_map[local.manager_to_bucket_map[user.manager]] :
                format("%s %s", local.existing_user_id_map[user.upn], local.existing_group_to_id_map[group])
        ]
    ])

    user_group_id_pairs_final = concat(local.user_group_id_pairs, local.user_existing_group_id_pairs)
}


output "testing1" {
    value = local.groups
}
// create groups_ids
resource "azuread_group" "csv_group" {
  for_each = {for group in local.groups : group.name => group}
  display_name = each.value.name
  owners = [var.sam_object_id]
  security_enabled = true
}


// get existing users
data "azuread_user" "existing_users" {
  for_each = {for user in local.users : user.upn => user}
  user_principal_name = format("%s%s", each.value.upn, var.azure_domain)
}

// apply group membership to users
resource "azuread_group_member" "group_membership" {
  for_each = {for user in local.user_group_id_pairs_final: user => user}
  // look up object ids for groups and members
  member_object_id = split(" ", each.value)[0]
  group_object_id  = split(" ", each.value)[1]
  depends_on          = [azuread_group.csv_group, data.azuread_user.existing_users]
}


output "printer3" {
    value = local.manager_to_bucket_map
}

output "printer6" {
    value = local.users
}

output "printer7" {
    value = local.existing_user_id_map
}

output "printer8" {
    value = local.user_group_id_pairs
}

output "printer9" {
    value = local.bucket_to_existing_groups
}
