<template>
  <v-flex xs12 sm8 md4>
    <v-card flat>
      <v-subheader>
        <span class="title">{{ $t("appBar.edit.title") }}</span>
      </v-subheader>
      <v-card-text class="pr-16 pl-16 pt-0 pb-0">
        <v-divider></v-divider>

        <v-select
          class="mt-4"
          :items="editableLayers"
          v-model="selectedLayer"
          item-value="values_.name"
          return-object
          solo
          :label="$t('appBar.edit.selectLayer')"
        >
          <template slot="selection" slot-scope="{ item }">
            {{ translate("layerName", item.get("name")) }}
          </template>
          <template slot="item" slot-scope="{ item }">
            {{ translate("layerName", item.get("name")) }}
          </template>
        </v-select>
        <v-divider></v-divider>
        <v-flex xs12 v-show="selectedLayer != null" class="mt-1 pt-0 mb-4">
          <p class="mb-1">{{ $t("appBar.edit.selectFeatures") }}</p>
          <v-btn-toggle v-model="toggleSelection">
            <v-tooltip top>
              <template v-slot:activator="{ on }">
                <v-btn v-on="on" text>
                  <v-icon>far fa-dot-circle</v-icon>
                </v-btn>
              </template>
              <span>{{ $t("appBar.edit.drawCircle") }}</span>
            </v-tooltip>
            <v-tooltip top>
              <template v-slot:activator="{ on }">
                <v-btn v-on="on" text v-show="false">
                  <v-icon>far fa-hand-pointer</v-icon>
                </v-btn>
              </template>
              <span>{{ $t("appBar.edit.selectOnMap") }}</span>
            </v-tooltip>
          </v-btn-toggle>
        </v-flex>
        <v-flex xs12 v-show="selectedLayer != null" class="mt-1 pt-0">
          <v-divider class="mb-1"></v-divider>
          <p class="mb-1">{{ $t("appBar.edit.editTools") }}</p>
          <v-btn-toggle v-model="toggleEdit">
            <v-tooltip top>
              <template v-slot:activator="{ on }">
                <v-btn v-on="on" text>
                  <v-icon medium>add</v-icon>
                </v-btn>
              </template>
              <span>{{ $t("appBar.edit.drawFeatureTooltip") }}</span>
            </v-tooltip>
            <v-tooltip top>
              <template v-slot:activator="{ on }">
                <v-btn v-on="on" text>
                  <v-icon>far fa-edit</v-icon>
                </v-btn>
              </template>
              <span>{{ $t("appBar.edit.modifyFeatureTooltip") }}</span>
            </v-tooltip>
            <v-tooltip top>
              <template v-slot:activator="{ on }">
                <v-btn v-on="on" text>
                  <v-icon>far fa-trash-alt</v-icon>
                </v-btn>
              </template>
              <span>{{ $t("appBar.edit.deleteFeature") }}</span>
            </v-tooltip>
          </v-btn-toggle>
          <v-divider class="mt-4"></v-divider>
        </v-flex>
      </v-card-text>

      <v-card-actions>
        <v-spacer></v-spacer>
        <!-- Logic only for road layer -->
        <v-btn
          v-show="selectedLayer != null && selectedLayer.get('name') === 'ways'"
          class="white--text"
          color="green"
          @click="uploadWaysFeatures"
        >
          <v-icon left>cloud_upload</v-icon>{{ $t("appBar.edit.uploadBtn") }}
        </v-btn>
        <!-- ---------------- -->
        <v-btn
          v-show="selectedLayer != null"
          class="white--text"
          color="green"
          @click="clear"
        >
          <v-icon left>delete</v-icon>{{ $t("appBar.edit.clearBtn") }}
        </v-btn>
      </v-card-actions>
    </v-card>
    <!-- Popup overlay  -->
    <overlay-popup :title="popup.title" v-show="popup.isVisible" ref="popup">
      <v-btn icon>
        <v-icon>close</v-icon>
      </v-btn>
      <template v-slot:close>
        <v-btn @click="olEditCtrl.closePopup()" icon>
          <v-icon>close</v-icon>
        </v-btn>
      </template>
      <template v-slot:body>
        <div v-if="popup.selectedInteraction === 'delete'">
          <b>{{ $t("appBar.edit.popup.deleteFeatureMsg") }}</b>
        </div>
        <div v-else-if="popup.selectedInteraction === 'add'">
          <span>{{ $t("appBar.edit.popup.selectWayType") }}</span>
          <v-select
            :items="waysTypes.values"
            item-value="value"
            v-model="waysTypes.active"
            @change="updateSelectedWaysType"
            :label="$t('appBar.edit.popup.wayType')"
            solo
            required
            class="pt-2 ma-0"
          >
            <template slot="selection" slot-scope="{ item }">
              {{ translate("layerListValues", item) }}
            </template>
            <template slot="item" slot-scope="{ item }">
              {{ translate("layerListValues", item) }}
            </template>
          </v-select>
        </div>
      </template>
      <template v-slot:actions>
        <template v-if="popup.selectedInteraction === 'delete'">
          <v-btn
            color="primary darken-1"
            @click="olEditCtrl.deleteFeature()"
            text
            >{{ $t("buttonLabels.yes") }}</v-btn
          >
          <v-btn color="grey" text @click="olEditCtrl.closePopup()">{{
            $t("buttonLabels.cancel")
          }}</v-btn>
        </template>
        <template v-else-if="popup.selectedInteraction === 'add'">
          <v-btn
            color="primary darken-1"
            @click="olEditCtrl.commitFeature()"
            text
            >{{ $t("buttonLabels.save") }}</v-btn
          >
          <v-btn color="grey" text @click="olEditCtrl.closePopup()">{{
            $t("buttonLabels.cancel")
          }}</v-btn>
        </template>
      </template>
    </overlay-popup>
  </v-flex>
</template>

<script>
import { EventBus } from "../../../EventBus";
import { Mapable } from "../../../mixins/Mapable";
import { InteractionsToggle } from "../../../mixins/InteractionsToggle";
import { getAllChildLayers } from "../../../utils/Layer";

import OlEditController from "../../../controllers/OlEditController";
import OlSelectController from "../../../controllers/OlSelectController";

import OlWaysLayerHelper from "../../../controllers/OlWaysLayerHelper";

import Overlay from "../../ol/Overlay";
import WaysLayerHelper from "../../../controllers/OlWaysLayerHelper";

export default {
  components: {
    "overlay-popup": Overlay
  },
  mixins: [InteractionsToggle, Mapable],
  data: () => ({
    interactionType: "edit-interaction",
    selectedLayer: null,
    selectedFeatures: [],
    editableLayers: [],
    toggleSelection: undefined,
    toggleEdit: undefined,
    popup: {
      title: "",
      isVisible: false,
      el: null,
      selectedInteraction: null
    },
    waysTypes: {
      values: ["bridge", "road"],
      active: "road"
    }
  }),
  watch: {
    toggleSelection: {
      handler(state) {
        const me = this;
        me.toggleSelectInteraction(state);
      }
    },
    toggleEdit: {
      handler(state) {
        const me = this;
        me.toggleEditInteraction(state);
      }
    }
  },
  mounted() {
    const me = this;
    me.popup.el = me.$refs.popup;
    me.olEditCtrl.referencePopupElement(me.popup);
  },
  methods: {
    /**
     * This function is executed, after the map is bound (see mixins/Mapable)
     */
    onMapBound() {
      const me = this;
      const editableLayers = getAllChildLayers(me.map).filter(layer =>
        layer.get("canEdit")
      );
      me.editableLayers = [...editableLayers];

      //Initialize ol select controllers.
      me.olSelectCtrl = new OlSelectController(me.map);
      me.olSelectCtrl.createSelectionLayer();

      //Initialize ol edit controller
      me.olEditCtrl = new OlEditController(me.map);
      me.olEditCtrl.createEditLayer();

      //Read or Insert ways deleted features
      me.olEditCtrl.readOrInsertDeletedWaysFeatures();
    },

    /**
     * Toggle the select interaction
     */
    toggleSelectInteraction(state) {
      const me = this;

      //Close other interactions.
      if (state != undefined) {
        EventBus.$emit("ol-interaction-activated", me.interactionType);
      } else {
        EventBus.$emit("ol-interaction-stoped", me.interactionType);
      }

      let selectionType;
      switch (state) {
        case 0:
          selectionType = "multiple";
          break;
        case 1:
          selectionType = "single";
          break;
        default:
          break;
      }
      if (selectionType !== undefined) {
        me.clearSelection();
        me.olSelectCtrl.addInteraction(
          selectionType,
          me.selectedLayer,
          me.onSelectionStart,
          me.onSelectionEnd
        );
      } else {
        me.olSelectCtrl.removeInteraction();
      }
    },

    /**
     * Toggle the edit interaction
     */
    toggleEditInteraction(state) {
      const me = this;
      //Remove select interaction
      me.olSelectCtrl.removeInteraction();
      me.toggleSelection = undefined;
      let editType;
      switch (state) {
        case 0:
          editType = "add";
          break;
        case 1:
          editType = "modify";
          break;
        case 2:
          editType = "delete";
          break;
        default:
          break;
      }
      if (editType !== undefined) {
        me.olEditCtrl.addInteraction(editType);
      } else {
        me.olEditCtrl.removeInteraction();
      }
    },

    /**
     * Callback function executed when selection interaction starts.
     */
    onSelectionStart() {
      const me = this;
      me.olEditCtrl.clear();
    },

    /**
     * Callback function executed when selection interaction ends.
     *
     * @param  {ol/feature} features The features returned from selection interaction
     */
    onSelectionEnd(response) {
      const me = this;
      me.toggleSelection = undefined;
      if (response.second) {
        //Selected layer is the road network (ways)
        OlWaysLayerHelper.filterResults(
          response,
          me.olEditCtrl.getLayerSource()
        );
      }
    },

    /**
     * Changes ways type between road or bridge
     */
    updateSelectedWaysType(value) {
      WaysLayerHelper.selectedWayType = value;
    },

    /**
     * Clears all the selection
     */
    clearSelection() {
      const me = this;
      me.olEditCtrl.clear();
      me.olSelectCtrl.clear();
    },

    uploadWaysFeatures() {
      this.olEditCtrl.uploadWaysFeatures();
    },

    /**
     * Clears  edit interaction
     */
    clearEdit() {
      const me = this;
      me.olEditCtrl.clear();
    },

    /**
     * Clears all the selection and edit interactions.
     */
    clear() {
      const me = this;
      me.clearSelection();
      me.clearEdit();
      me.toggleSelection = undefined;
      me.toggleEdit = undefined;
      EventBus.$emit("ol-interaction-stoped", me.interactionType);
    },
    /**
     * Stop edit and select interactions (Doesn't deletes the features)
     */
    stop() {
      const me = this;
      me.olSelectCtrl.removeInteraction();
      me.olEditCtrl.removeInteraction();
      EventBus.$emit("ol-interaction-stoped", me.interactionType);
    },
    translate(type, key) {
      //type = {layerGroup || layerName}
      //Checks if key exists and translates it othewise return the input value

      const canTranslate = this.$te(`map.${type}.${key}`);
      if (canTranslate) {
        return this.$t(`map.${type}.${key}`);
      } else {
        return key;
      }
    }
  }
};
</script>
