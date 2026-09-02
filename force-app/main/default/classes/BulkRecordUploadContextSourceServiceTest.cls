@IsTest
private class BulkRecordUploadContextSourceServiceTest {
  @IsTest
  static void buildContextProjection_BlankFieldLists_DefaultToNameField() {
    BulkRecordUploadContextProjection projection = new BulkRecordUploadContextSourceService()
      .buildContextProjection('USER_CHOICE', 'Account', null, null, null);

    Assert.areEqual(
      'Name',
      projection.primarySearchField,
      'A blank search field list should default to the name field.'
    );
    Assert.isTrue(projection.additionalSearchFields.isEmpty());
    Assert.areEqual(
      'Name',
      projection.primaryDisplayField,
      'A blank display field list should default to the name field.'
    );
    Assert.isTrue(projection.additionalDisplayFields.isEmpty());
    Assert.isTrue(projection.filterConditions.isEmpty());
  }

  @IsTest
  static void buildContextProjection_ConfiguredLists_SeparatesPrimaryFromAdditional() {
    BulkRecordUploadContextProjection projection = new BulkRecordUploadContextSourceService()
      .buildContextProjection(
        'USER_CHOICE',
        'Account',
        'Name, AccountNumber',
        'Name, Industry',
        null
      );

    Assert.areEqual('Name', projection.primarySearchField);
    Assert.areEqual(
      new List<String>{ 'AccountNumber' },
      projection.additionalSearchFields
    );
    Assert.areEqual('Name', projection.primaryDisplayField);
    Assert.areEqual(
      new List<String>{ 'Industry' },
      projection.additionalDisplayFields
    );
  }

  @IsTest
  static void buildContextProjection_UnknownSearchField_ThrowsSafeException() {
    try {
      new BulkRecordUploadContextSourceService()
        .buildContextProjection(
          'USER_CHOICE',
          'Account',
          'Not_A_Real_Field__c',
          null,
          null
        );
      Assert.fail('Expected an unavailable field to fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('unavailable'),
        'Failure should be admin-actionable and name the field.'
      );
      Assert.isTrue(error.getMessage().contains('Not_A_Real_Field__c'));
    }
  }

  @IsTest
  static void buildContextProjection_NonSearchableSearchField_ThrowsSafeException() {
    try {
      new BulkRecordUploadContextSourceService()
        .buildContextProjection(
          'USER_CHOICE',
          'Account',
          'Description',
          null,
          null
        );
      Assert.fail('Expected a non-filterable search field to fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('not searchable'),
        'Failure should name the unsearchable field.'
      );
    }
  }

  @IsTest
  static void buildContextProjection_TooManyAdditionalFields_ThrowsSafeException() {
    try {
      new BulkRecordUploadContextSourceService()
        .buildContextProjection(
          'USER_CHOICE',
          'Account',
          'Name,AccountNumber,Industry,Website,Phone',
          null,
          null
        );
      Assert.fail('Expected the platform cap to be enforced at validation.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('Too many'),
        'Failure should explain the field-count cap.'
      );
    }
  }

  @IsTest
  static void buildContextProjection_FilterCriteria_ParsesEqualsNotEqualsAndIn() {
    Account first = BulkRecordUploadTestDataFactory.createAccount('First');
    Account second = BulkRecordUploadTestDataFactory.createAccount('Second');
    BulkRecordUploadContextProjection projection = new BulkRecordUploadContextSourceService()
      .buildContextProjection(
        'USER_CHOICE',
        'Account',
        null,
        null,
        'Industry:=:Technology\nIndustry:!=:Government\nId:IN:' +
          first.Id +
          ',' +
          second.Id
      );

    Assert.areEqual(3, projection.filterConditions.size());
    Assert.areEqual('Industry', projection.filterConditions[0].fieldApiName);
    Assert.areEqual('=', projection.filterConditions[0].operatorCode);
    Assert.areEqual('!=', projection.filterConditions[1].operatorCode);
    Assert.areEqual('IN', projection.filterConditions[2].operatorCode);
    Assert.areEqual(
      new List<String>{ first.Id, second.Id },
      projection.filterConditions[2].values
    );
  }

  @IsTest
  static void buildContextProjection_InvalidFilterCondition_ThrowsSafeException() {
    try {
      new BulkRecordUploadContextSourceService()
        .buildContextProjection(
          'USER_CHOICE',
          'Account',
          null,
          null,
          'Industry:Technology'
        );
      Assert.fail('Expected a malformed condition to fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('not valid'));
    }
  }

  @IsTest
  static void buildContextProjection_UnsupportedFilterOperator_ThrowsSafeException() {
    try {
      new BulkRecordUploadContextSourceService()
        .buildContextProjection(
          'USER_CHOICE',
          'Account',
          null,
          null,
          'Industry:LIKE:Tech'
        );
      Assert.fail('Expected an unsupported operator to fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('not supported'));
    }
  }

  @IsTest
  static void isEligible_MatchingCondition_ReturnsTrue() {
    Account matching = BulkRecordUploadTestDataFactory.createAccountWithIndustry(
      'Eligible Co',
      'Technology'
    );

    Boolean eligible = new BulkRecordUploadContextSourceService()
      .isEligible(
        'Account',
        matching.Id,
        new List<BulkRecordUploadContextFilterCondition>{
          new BulkRecordUploadContextFilterCondition(
            'Industry',
            '=',
            new List<String>{ 'Technology' }
          )
        }
      );

    Assert.isTrue(eligible);
  }

  @IsTest
  static void isEligible_NonMatchingCondition_ReturnsFalse() {
    Account nonMatching = BulkRecordUploadTestDataFactory.createAccountWithIndustry(
      'Ineligible Co',
      'Retail'
    );

    Boolean eligible = new BulkRecordUploadContextSourceService()
      .isEligible(
        'Account',
        nonMatching.Id,
        new List<BulkRecordUploadContextFilterCondition>{
          new BulkRecordUploadContextFilterCondition(
            'Industry',
            '=',
            new List<String>{ 'Technology' }
          )
        }
      );

    Assert.isFalse(eligible);
  }

  @IsTest
  static void isEligible_IdInFilter_RejectsVisibleNonMember() {
    Account member = BulkRecordUploadTestDataFactory.createAccount('Member');
    Account nonMember = BulkRecordUploadTestDataFactory.createAccount(
      'Non Member'
    );

    Boolean memberEligible = new BulkRecordUploadContextSourceService()
      .isEligible(
        'Account',
        member.Id,
        new List<BulkRecordUploadContextFilterCondition>{
          new BulkRecordUploadContextFilterCondition(
            'Id',
            'IN',
            new List<String>{ member.Id }
          )
        }
      );
    Boolean nonMemberEligible = new BulkRecordUploadContextSourceService()
      .isEligible(
        'Account',
        nonMember.Id,
        new List<BulkRecordUploadContextFilterCondition>{
          new BulkRecordUploadContextFilterCondition(
            'Id',
            'IN',
            new List<String>{ member.Id }
          )
        }
      );

    Assert.isTrue(memberEligible, 'The Id IN member should be eligible.');
    Assert.isFalse(
      nonMemberEligible,
      'A visible non-member must be rejected by the Id IN filter.'
    );
  }
}
