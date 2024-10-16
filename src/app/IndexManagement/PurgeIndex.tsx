import React from 'react';
import { Button, ButtonVariant, Modal, Text, TextContent } from '@patternfly/react-core';
import { useApiAlert } from '@app/utils/useApiAlert';
import { useTranslation } from 'react-i18next';
import { ConsoleServices } from '@services/ConsoleServices';

/**
 * Purge index modal
 */
const PurgeIndex = (props: { cacheName: string; isModalOpen: boolean; closeModal: () => void }) => {
  const { t } = useTranslation();
  const { addAlert } = useApiAlert();

  const onClickPurgeButton = () => {
    ConsoleServices.search()
      .purgeIndexes(props.cacheName)
      .then((actionResponse) => {
        props.closeModal();
        addAlert(actionResponse);
      });
  };

  return (
    <Modal
      titleIconVariant={'warning'}
      width={'50%'}
      isOpen={props.isModalOpen}
      title={t('caches.index.purge.title')}
      onClose={props.closeModal}
      aria-label="Clear index modal"
      actions={[
        <Button data-cy="clearIndex" key="purge" variant={ButtonVariant.danger} onClick={onClickPurgeButton}>
          {t('common.actions.clear')}
        </Button>,
        <Button data-cy="cancelButton" key="cancel" variant="link" onClick={props.closeModal}>
          {t('common.actions.cancel')}
        </Button>
      ]}
    >
      <TextContent>
        <Text>
          {t('caches.index.purge.description1')} <strong>{props.cacheName}</strong>{' '}
          {t('caches.index.purge.description2')}
        </Text>
      </TextContent>
    </Modal>
  );
};

export { PurgeIndex };
